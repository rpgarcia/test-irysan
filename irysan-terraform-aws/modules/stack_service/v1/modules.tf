module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.0.0"

  create_certificate = !var.path_routing_enabled

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  create_route53_records = false
  validation_method      = "DNS"

  tags = var.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  create = var.create_alb && !var.use_existing_alb

  name = var.name

  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  enable_deletion_protection = true
  create_security_group      = false

  security_groups = var.create_alb && !var.use_existing_alb ? [aws_security_group.alb.0.id] : [var.existing_alb_security_group_id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "tg_ecs"
      }
    }
    https = {
      port     = 443
      protocol = "HTTPS"

      certificate_arn = module.acm.acm_certificate_arn

      forward = {
        target_group_key = "tg_ecs"
      }
    }
  }

  target_groups = {
    tg_ecs = {
      backend_protocol                  = "TCP"
      backend_port                      = var.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200-301"
        path                = var.healthcheck_path
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      # Theres nothing to attach here in this definition. Instead,
      # ECS will attach the IPs of the tasks to this target group
      create_attachment = false
    }
  }

  tags = var.tags
}

#only attaches when it should use an already existing alb
resource "aws_lb_listener_certificate" "certificate" {
  # in case we don't want ACM don't create a certificate
  count = var.path_routing_enabled ? 0 : (var.use_existing_alb ? 1 : 0)

  listener_arn    = var.existing_alb_https_listener_arn
  certificate_arn = module.acm.acm_certificate_arn
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.8.0"

  cluster_name = var.name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
        base   = 20
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  services = {
    (var.service_name) = {
      container_definitions = var.container_definitions

      enable_execute_command = true
      
      # Autoscaling
      enable_autoscaling       = var.enable_autoscaling
      autoscaling_min_capacity = var.autoscaling_min_capacity
      autoscaling_max_capacity = var.autoscaling_max_capacity
      desired_count            = var.desired_count

      load_balancer = {
        service = {
          target_group_arn = var.use_existing_alb ? aws_alb_target_group.override[0].arn : module.alb.target_groups["tg_ecs"].arn
          container_name   = var.container_name
          container_port   = var.container_port
        }
      }

      cpu                        = var.cpu_task
      memory                     = var.memory_task
      tasks_iam_role_name        = "${var.name}-tasks"
      tasks_iam_role_description = "Tasks IAM role for ${var.name}"
      tasks_iam_role_policies    = local.tasks_iam_role_policies

      subnet_ids          = var.private_subnets
      security_group_name = "ecs"
      # security_group_use_name_prefix = "ecs"
      security_group_rules = {
        alb_ingress_container_port = {
          type                     = "ingress"
          from_port                = var.container_port
          to_port                  = var.container_port
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = var.use_existing_alb ? var.existing_alb_security_group_id : aws_security_group.alb.0.id
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_alb_target_group" "override" {
  count = var.use_existing_alb ? 1 : 0

  name = "${var.name}-tg"

  target_type = "ip"
  port        = var.container_port
  protocol    = "HTTP"

  vpc_id = var.vpc_id

  health_check {
    healthy_threshold   = coalesce(var.tg_threshold, var.tg_health_check["healthy_threshold"])
    interval            = coalesce(var.tg_interval, var.tg_health_check["interval"])
    unhealthy_threshold = coalesce(var.tg_unhealthy_threshold, var.tg_health_check["unhealthy_threshold"])
    timeout             = coalesce(var.tg_timeout, var.tg_health_check["timeout"])
    path                = coalesce(var.healthcheck_path, var.tg_health_check["path"])
    port                = coalesce(var.container_port, var.tg_health_check["port"])
    matcher             = coalesce(var.healthcheck_matcher, var.tg_health_check["success_codes"])
  }
}

resource "aws_lb_listener_rule" "host_rule_http" {
  listener_arn = var.use_existing_alb ? var.existing_alb_http_listener_arn : module.alb.listeners["http"].arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = var.use_existing_alb ? aws_alb_target_group.override[0].arn : module.alb.target_groups["tg_ecs"].arn
  }

  dynamic "condition" {
    for_each = var.path_routing_enabled ? [1] : []
    content {
      path_pattern {
        values = [var.routing_path]
      }
    }
  }

  condition {
    host_header {
      values = local.all_domains
    }
  }
}

resource "aws_lb_listener_rule" "host_rule_https" {
  listener_arn = var.use_existing_alb ? var.existing_alb_https_listener_arn : module.alb.listeners["https"].arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = var.use_existing_alb ? aws_alb_target_group.override[0].arn : module.alb.target_groups["tg_ecs"].arn
  }

  dynamic "condition" {
    for_each = var.path_routing_enabled ? [1] : []
    content {
      path_pattern {
        values = [var.routing_path]
      }
    }
  }

  condition {
    host_header {
      values = length(var.alb_rule_host_header_domain) > 0 ? var.alb_rule_host_header_domain : local.all_domains
    }
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.4.0"

  create_db_instance          = var.create_db
  create_cloudwatch_log_group = true
  create_monitoring_role      = false
  create_db_parameter_group   = var.create_db

  # Snnapshots
  snapshot_identifier              = var.snapshot_identifier
  # copy_tags_to_snapshot            = var.copy_tags_to_snapshot
  # skip_final_snapshot              = var.skip_final_snapshot
  # final_snapshot_identifier_prefix = var.final_snapshot_identifier_prefix

  identifier = var.name

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  family               = var.db_family               # DB parameter group
  major_engine_version = var.db_major_engine_version # DB option group
  option_group_name    =  var.option_group_name 
  create_db_option_group = var.create_db_option_group 
  instance_class       = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 100

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = var.db_name
  username = var.db_username != null ? var.db_username : lookup(local.db_username, var.db_engine, "admin")
  # username = lookup(local.db_username, var.db_engine, "admin")
  port = lookup(local.db_port_auto, var.db_engine, "5432")

  # setting manage_master_user_password_rotation to false after it
  # has been set to true previously disables automatic rotation
  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = var.db_multi_az
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = local.db_vpc_security_group_ids

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = var.tags
}

module "cloudposse_redis_context" {
  source  = "cloudposse/label/null"
  version = "0.25.0" # requires Terraform >= 0.13.0

  #count = var.redis_create ? 1 : 0
}

module "redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "1.2.0"

  count = var.redis_create ? 1 : 0

  availability_zones            = var.redis_availability_zones
  description                   = "redis-${var.redis_description}"
  vpc_id                        = var.vpc_id
  create_security_group         = false
  allowed_security_group_ids    = [aws_security_group.redis.0.id]
  associated_security_group_ids = [aws_security_group.redis.0.id]
  elasticache_subnet_group_name = var.elasticache_subnet_group_name
  subnets                       = var.elasticache_subnets
  replication_group_id          = var.replication_group_id
  cluster_size                  = var.redis_cluster_size
  instance_type                 = var.redis_instance_type
  apply_immediately             = true
  automatic_failover_enabled    = false
  engine_version                = var.redis_engine_version
  family                        = var.redis_family # Redis Parameter group
  parameter_group_name          = var.redis_parameter_group_name
  # aws_elasticache_parameter_group   = var.redis_family
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
  transit_encryption_enabled = var.redis_transit_encryption_enabled

  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]

  context = module.cloudposse_redis_context
}

module "memcached" {
  source  = "cloudposse/elasticache-memcached/aws"
  version = "0.19.0"

  count = var.memcached_create ? 1 : 0

  name                    = "memcached-${var.name}"
  az_mode                 = local.memcached_az_mode
  availability_zone       = var.memcached_availability_zone
  vpc_id                  = var.vpc_id
  allowed_security_groups = [aws_security_group.memcached.0.id]
  subnets                 = var.memcached_subnets
  cluster_size            = var.memcached_cluster_size
  instance_type           = var.memcached_instance_type
  engine_version          = var.memcached_engine_version
  apply_immediately       = local.memcached_apply_immediately
  zone_id                 = var.memcached_zone_id

  elasticache_parameter_group_family = var.memcached_elasticache_parameter_group_family
}

module "s3_bucket_a" {
  source = "terraform-aws-modules/s3-bucket/aws"

  create_bucket = var.s3_bucket_a_create

  bucket = var.s3_bucket_a_name
  acl    = "null"

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    status     = var.s3_bucket_a_versioning
    mfa_delete = false
  }

  logging = {
    target_bucket = var.s3_bucket_a_access_logs_bucket_id
    target_prefix = "${var.s3_bucket_a_name}/"
  }

  attach_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = length(var.s3_bucket_a_policy_statements) > 0 ? var.s3_bucket_a_policy_statements : [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.s3_bucket_a_name}/*"
      }
    ]
  })
}
