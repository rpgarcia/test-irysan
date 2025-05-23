data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_ec2_instance_type" "rds" {
  count = var.create_db ? 1 : 0

  instance_type = trimprefix(var.db_instance_class, "db.") # instance class approximation.
}

locals {
  rds_instance_memory_in_mb = var.create_db ? data.aws_ec2_instance_type.rds[0].memory_size : 1024 # set 1024 as default.

  # db_connections calculation => LEAST({DBInstanceClassMemory/9531392}, 5000).
  rds_memodr_in_bytes = (local.rds_instance_memory_in_mb * 1024 * 1024)
  rds_db_connections  = min((local.rds_memodr_in_bytes / 9531392), 5000)

  # Get ECS mempry from container_definitions.
  ecs_task_memory_in_mb = var.container_definitions[var.container_name]["memory"]

  # Alarm Thresholds when applying %.
  ecs_mem_alarm_threshold_in_mb          = floor(local.ecs_task_memory_in_mb * 0.8) # 80% of total MBs of the ECS.
  rds_connections_alarm_threshold_in_int = floor(local.rds_db_connections * 0.8)    # 80% of max_connections of the RDS.
}

module "alerts_sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "5.4.0"

  create = var.create_alarms

  name = "${var.name}-opsgenie"

  topic_policy_statements = {
    pub = {
      actions = ["sns:Publish"]
      principals = [{
        type        = "Service"
        identifiers = ["cloudwatch.amazonaws.com"]
      }]
      conditions = [
        {
          test     = "ArnLike"
          variable = "aws:SourceArn"
          values   = ["arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"]
        },
        {
          test     = "StringEquals"
          variable = "aws:SourceAccount"
          values   = [data.aws_caller_identity.current.account_id]
        },
      ]
    }
  }

  subscriptions = {
    opsgenie = {
      protocol = "https"
      endpoint = "${var.opsgenie_endpoint}${local.opsgenie_key}"
    }
  }

  tags = var.tags
}

# ECS CPUUtilization bigger than 80% for more than 5min.
module "ecs_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  create_metric_alarm = var.create_alarms

  alarm_name          = "${var.name}-alarm-ecs-cpu"
  alarm_description   = "CPU for ECS cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 5 * 60

  dimensions = {
    ClusterName          = module.ecs.cluster_name
    TaskDefinitionFamily = module.ecs.cluster_name
  }

  namespace   = "ECS/ContainerInsights"
  metric_name = "CpuUtilized"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# ECS MemoryUtilization bigger than 80% for more than 5min.
module "ecs_mem_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  create_metric_alarm = var.create_alarms

  alarm_name          = "${var.name}-alarm-ecs-mem"
  alarm_description   = "Memory for ECS task definition family >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.ecs_mem_alarm_threshold_in_mb
  period              = 5 * 60

  dimensions = {
    ClusterName          = module.ecs.cluster_name
    TaskDefinitionFamily = module.ecs.cluster_name
  }

  namespace   = "ECS/ContainerInsights"
  metric_name = "MemoryUtilized"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# RDS CPUUtilization bigger than 80% for more than 5min.
module "rds_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.create_db ? 1 : 0
  create_metric_alarm = var.create_alarms && var.create_db

  alarm_name          = "${var.name}-alarm-rds-cpu"
  alarm_description   = "CPU for RDS cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 5 * 60

  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_identifier
  }

  namespace   = "AWS/RDS"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# RDS FreeStorageSpace smaller than 20%.
module "rds_storage_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.create_db ? 1 : 0
  create_metric_alarm = var.create_alarms && var.create_db

  alarm_name          = "${var.name}-alarm-rds-storage"
  alarm_description   = "FreeStorage for RDS cluster <= 20%"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1073741824 # in bytes, RDS storage is 20 GiB (gibibytes)
  period              = 5 * 60

  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_identifier
  }

  namespace   = "AWS/RDS"
  metric_name = "FreeStorageSpace"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# RDS DatabaseConnections bigger than 80% for more than 5min for instance type.
module "rds_connections_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.create_db ? 1 : 0
  create_metric_alarm = var.create_alarms && var.create_db

  alarm_name          = "${var.name}-alarm-rds-connections"
  alarm_description   = "DatabaseConnections for RDS cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = local.rds_connections_alarm_threshold_in_int
  period              = 5 * 60

  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_identifier
  }

  namespace   = "AWS/RDS"
  metric_name = "DatabaseConnections"
  statistic   = "Maximum"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# Redis - CPUUtilization bigger than 80% for more than 5min.
module "redis_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.redis_create ? 1 : 0
  create_metric_alarm = var.create_alarms && var.redis_create

  alarm_name          = "${var.name}-alarm-redis-cpu"
  alarm_description   = "CPU for Redis cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 5 * 60

  dimensions = {
    CacheClusterId = module.redis[0].id
  }

  namespace   = "AWS/ElastiCache"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# Redis - MemoryUsage bigger than 80% for more than 5min.
module "redis_memory_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.redis_create ? 1 : 0
  create_metric_alarm = var.create_alarms && var.redis_create

  alarm_name          = "${var.name}-alarm-redis-memory"
  alarm_description   = "Memory for Redis cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 5 * 60

  dimensions = {
    CacheClusterId = module.redis[0].id
  }

  namespace   = "AWS/ElastiCache"
  metric_name = "DatabaseMemoryUsagePercentage"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# Memcached - CPUUtilization bigger than 80% for more than 5min.
module "memcached_cpu_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.memcached_create ? 1 : 0
  create_metric_alarm = var.create_alarms && var.memcached_create

  alarm_name          = "${var.name}-alarm-memcached-cpu"
  alarm_description   = "CPU for Memcached cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 5 * 60

  dimensions = {
    CacheClusterId = module.memcached[0].cluster_id
  }

  namespace   = "AWS/ElastiCache"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}

# Memcached - MemoryUsage bigger than 80% for more than 5min.
module "memcached_memory_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "~> 3.0"

  count               = var.create_alarms && var.memcached_create ? 1 : 0
  create_metric_alarm = var.create_alarms && var.memcached_create

  alarm_name          = "${var.name}-alarm-memcached-memory"
  alarm_description   = "Memory for Memcached cluster >= 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 5 * 60

  dimensions = {
    CacheClusterId = module.memcached[0].cluster_id
  }

  namespace   = "AWS/ElastiCache"
  metric_name = "DatabaseMemoryUsagePercentage"
  statistic   = "Average"

  alarm_actions = [module.alerts_sns_topic.topic_arn]

  tags = var.tags
}
