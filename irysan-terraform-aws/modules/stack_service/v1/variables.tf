variable "environment" {
  type        = string
  description = "Environment name"
}

variable "name" {
  description = "Name to be used on all the resources as identifier"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The VPC ID where to the deploy the ecs service"
  nullable    = false
}

variable "vpc_cidr_block" {
  description = "The VPC CIDR to use for alb egress"
  nullable    = false
}

variable "private_subnets" {
  description = "Lists of the private subnets where to deploy the ecs service"
  type        = list(string)
  nullable    = false
}

variable "public_subnets" {
  description = "Lists of the public subnets where to deploy the load balancer"
  type        = list(string)
  nullable    = false
}

variable "create_alb" {
  description = "Should create the alb"
  type        = bool
  default     = true
}

variable "path_routing_enabled" {
  description = "IF we will use a path routing or not"
  type        = bool
  default     = false
}

variable "routing_path" {
  description = "The path that will be used in case we want to have path routing"
  type        = string
  default     = ""
}

variable "container_port" {
  description = "The container port used to connect by the alb target group"
  type        = number
}

variable "healthcheck_path" {
  description = "The alb target group health check path"
  type        = string
  default     = "/health"
}

variable "healthcheck_matcher" {
  description = "The alb target group success response codes"
  type        = string
  default     = "200-301"
}

variable "service_name" {
  description = "The alb target group health check path"
  type        = string
}

variable "container_name" {
  description = "The alb target group health check path"
  type        = string
}

variable "container_definitions" {
  description = "Map of container definitions to create"
  type        = any
  default     = {}
}

variable "domain_name" {
  description = "A domain name for which the certificate should be issued"
  type        = string
}

variable "subject_alternative_names" {
  description = "A list of domains that should be SANs in the issued certificate"
  type        = list(string)
  default     = []
}

variable "use_existing_alb" {
  description = "If specified, the ecs service will be configured to attach to an existing alb"
  type        = bool
  default     = false
}

variable "alb_rule_host_header_domain" {
  description = "Domain Host Header rule for ALB"
  type        = list(string)
  default     = []
}

variable "existing_alb_http_listener_arn" {
  description = "Used to attach the rules to the alb when using an existing alb"
  type        = string
  default     = ""
}

variable "existing_alb_https_listener_arn" {
  description = "Used to attach the rules and ssl cert to the alb when using an existing alb"
  type        = string
  default     = ""
}

variable "existing_alb_security_group_id" {
  description = "Used to attach the security groupd to the ecs service when using an existing alb"
  type        = string
  default     = ""
}

variable "alb_listener_rule_priority" {
  description = "Used to set the priority of the host rule in the listener"
  type        = number
  default     = 100
}

variable "create_db" {
  description = "Whether to create a database instance"
  type        = bool
  default     = false
}

variable "db_engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "The engine version to use"
  type        = string
  default     = "14"
}

variable "db_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "postgres14"
}

variable "db_major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with"
  type        = string
  default     = "14"
}

variable "option_group_name" {
  type = string
  default = ""
}

variable "create_db_option_group" {
  default = true
  type = string
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = string
  default     = null
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = null
}

variable "db_port" {
  description = "The port on which the DB accepts connections"
  type        = string
  default     = 5432
}

variable "db_multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC"
  type        = string
  default     = null
}

variable "db_vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
  default     = []
}

// ####### Redis Variables. ####### //
variable "redis_create" {
  description = "Controls if a Redis server should be created"
  type        = bool
  default     = false
}

variable "redis_automatic_failover_enabled" {
  type        = bool
  default     = false
  description = "Automatic failover (Not available for T1/T2 instances)"
}

variable "redis_multi_az_enabled" {
  type        = bool
  default     = false
  description = "Multi AZ (Automatic Failover must also be enabled.  If Cluster Mode is enabled, Multi AZ is on by default, and this setting is ignored)"
}

variable "elasticache_subnet_group_name" {
  description = "Subnet group name for the ElastiCache instance"
  type        = string
  default     = null
}

variable "elasticache_subnets" {
  description = "Name of elasticache subnet group. Elasticache instance will be created in the VPC associated with the Elasticache subnet group. If unspecified, will be created in the default VPC"
  type        = list(string)
  default     = []
}

variable "redis_availability_zones" {
  description = "Availability zone IDs"
  type        = list(string)
  default     = []
}

variable "redis_vpc_security_group_ids" {
  description = "List of VPC security groups to associate"
  type        = list(string)
  default     = []
}

variable "redis_cluster_size" {
  description = ""
  type        = string
  default     = "1"
}

variable "redis_instance_type" {
  description = "Elastic cache instance type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_family" {
  description = "Redis family"
  type        = string
  default     = "redis7"
}

variable "redis_at_rest_encryption_enabled" {
  description = "Enable encryption at rest"
  type        = bool
  default     = false
}

variable "redis_transit_encryption_enabled" {
  description = "Enable TLS"
  type        = bool
  default     = false
}

variable "cloudposse_redis_context" {
  type    = any
  default = {}
}

variable "redis_description" {
  description = "Redis description"
  type        = string
  default     = "redis"
}

variable "redis_parameter_group_name" {
  description = "Redis parameter group name"
  type        = string
  default     = "default-redis7"
}

// ####### Memcached Variables. ####### //
variable "memcached_create" {
  description = "Controls if a Memcached server should be created"
  type        = bool
  default     = false
}

variable "memcached_availability_zone" {
  description = "Single Availability zone ID"
  type        = string
  default     = ""
}

variable "memcached_subnets" {
  description = "Name of elasticache subnet group. Elasticache instance will be created in the VPC associated with the Elasticache subnet group. If unspecified, will be created in the default VPC"
  type        = list(string)
  default     = []
}

variable "memcached_cluster_size" {
  description = "Memcached cluster size"
  type        = number
  default     = 1
}

variable "memcached_instance_type" {
  description = "Memcached instance type"
  type        = string
  default     = "cache.t2.micro"
}

variable "memcached_engine_version" {
  description = "Memcached engine version. For more info, see https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/supported-engine-versions.html"
  type        = string
  default     = "1.5.16"
}

variable "memcached_zone_id" {
  description = "Route53 DNS Zone ID"
  type        = string
  default     = ""
}

variable "memcached_elasticache_parameter_group_family" {
  type        = string
  description = "ElastiCache parameter group family"
  default     = "memcached1.5"
}

variable "replication_group_id" {
  type        = string
  description = "Replication group ID with the following constraints: \nA name must contain from 1 to 20 alphanumeric characters or hyphens. \n The first character must be a letter. \n A name cannot end with a hyphen or contain two consecutive hyphens."
  default     = ""
}

variable "s3_bucket_a_create" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = false
}

variable "s3_bucket_a_name" {
  description = "(Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = ""
}

variable "s3_bucket_a_access_logs_bucket_id" {
  description = "The inventory source account id."
  type        = string
  default     = null
}

variable "s3_bucket_a_versioning" {
  description = "Controls if S3 bucket should be versioned"
  type        = bool
  default     = false
}

variable "tg_health_check" {
  description = "Health Check for Target Group"
  type        = map(string)
  default = {
    "timeout"             = "5"
    "interval"            = "30"
    "path"                = "/health"
    "port"                = "80"
    "unhealthy_threshold" = "2"
    "healthy_threshold"   = "5"
    "success_codes"       = "200-301"
  }
}

variable "tg_threshold" {
  description = "Threshold for TG"
  type        = string
  default     = null
}

variable "tg_interval" {
  description = "Interval for TG"
  type        = string
  default     = null
}

variable "tg_unhealthy_threshold" {
  description = "Unhealthy threshold for TG"
  type        = string
  default     = null
}

variable "tg_timeout" {
  description = "Timeout for TG"
  type        = string
  default     = null
}

variable "create_alarms" {
  default = false
}

variable "alarms_priority" {
  type        = string
  description = "The priority to use in OpsGenie [P1|P2|P3]"
  default     = "P3"
}

variable "opsgenie_endpoint" {
  type    = string
  default = "https://api.eu.opsgenie.com/v1/json/cloudwatch?apiKey="
}

variable "opsgenie_key_p1" {
  type    = string
  default = ""
}

variable "opsgenie_key_p2" {
  type    = string
  default = ""
}

variable "opsgenie_key_p3" {
  type    = string
  default = ""
}

variable "create_migrations_task_definition" {
  default = false
}

variable "migrations_task_definition" {
  type    = any
  default = {}
}

variable "enable_autoscaling" {
  description = "Enable autoscaling - Default value in aws ecs module is true"
  type        = bool
  default     = false
}

variable "cpu_task" {
  description = "CPU for task definition"
  type        = number
  default     = 512
}

variable "memory_task" {
  description = "Memory for task definition"
  type        = number
  default     = 1024
}

variable "s3_bucket_a_policy_statements" {
  description = "List of policy statements for the s3 bucket"
  type = list(object({
    Effect    = string
    Principal = any
    Action    = string
    Resource  = string
  }))
  default = []
}

variable "create_secret_manager" {
  description = "Value to create or not from stack_service the secret manager resource (deprecated)"
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks to run in your service"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks to run in your service"
  type        = number
  default     = 1
}

variable "desired_count" {
  description = "Number of tasks to run in your service"
  type        = number
  default     = 1
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05"
  type        = string
  default     = null
}