resource "aws_security_group" "alb" {
  count = var.use_existing_alb ? 0 : 1

  name        = "alb-${var.name}"
  description = "Security group for ${var.name} application load balancer"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_ipv4_ingress_rules" {
  for_each          = { for entry in var.use_existing_alb ? [] : local.cloudflare_ingress_ipv4 : "${entry.port}.${entry.ip}" => entry }
  description       = "allow from ipv4 ${each.value.ip} on port ${each.value.port}"
  security_group_id = aws_security_group.alb.0.id
  cidr_ipv4         = each.value.ip
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ipv6_ingress_rules" {
  for_each          = { for entry in var.use_existing_alb ? [] : local.cloudflare_ingress_ipv6 : "${entry.port}.${entry.ip}" => entry }
  description       = "allow from ipv6 ${each.value.ip} on port ${each.value.port}"
  security_group_id = aws_security_group.alb.0.id
  cidr_ipv6         = each.value.ip
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_ipv4_ingress_rules" {
  count = var.use_existing_alb ? 0 : 1

  description       = "allow to ipv4 0.0.0.0/0"
  security_group_id = aws_security_group.alb.0.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}

resource "aws_vpc_security_group_egress_rule" "alb_ipv6_ingress_rules" {
  count = var.use_existing_alb ? 0 : 1

  description       = "allow to ipv6 ::0/0"
  security_group_id = aws_security_group.alb.0.id
  cidr_ipv6         = "::/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}


resource "aws_security_group" "rds" {
  count = var.create_db ? 1 : 0

  name        = "rds-${var.name}"
  description = "Security group for ${var.name} RDS"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "rds_ipv4_ingress_rules" {
  count = var.create_db ? 1 : 0

  security_group_id            = aws_security_group.rds.0.id
  from_port                    = lookup(local.db_port_auto, var.db_engine, "5432")
  to_port                      = lookup(local.db_port_auto, var.db_engine, "5432")
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.ecs.services[var.service_name].security_group_id
}

resource "aws_vpc_security_group_egress_rule" "rds_ipv4_ingress_rules" {
  count = var.create_db ? 1 : 0

  description       = "allow to ipv4 0.0.0.0/0"
  security_group_id = aws_security_group.rds.0.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}

resource "aws_security_group" "redis" {
  count = var.redis_create ? 1 : 0

  name        = "redis-${var.name}"
  description = "Security group for ${var.name} Redis"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "redis_ipv4_ingress_rules" {
  count = var.redis_create ? 1 : 0

  security_group_id            = aws_security_group.redis.0.id
  from_port                    = 6369
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.ecs.services[var.service_name].security_group_id
}

resource "aws_vpc_security_group_egress_rule" "redis_ipv4_ingress_rules" {
  count = var.redis_create ? 1 : 0

  description       = "allow to ipv4 0.0.0.0/0"
  security_group_id = aws_security_group.redis.0.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}

resource "aws_security_group" "memcached" {
  count = var.memcached_create ? 1 : 0

  name        = "memcached-${var.name}"
  description = "Security group for ${var.name} Memcached"
  vpc_id      = var.vpc_id

}

resource "aws_vpc_security_group_ingress_rule" "memcached_ipv4_ingress_rules" {
  count = var.memcached_create ? 1 : 0

  security_group_id            = aws_security_group.memcached.0.id
  from_port                    = local.memcached_port
  to_port                      = local.memcached_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = module.ecs.services[var.service_name].security_group_id
}

resource "aws_vpc_security_group_egress_rule" "memcached_ipv4_ingress_rules" {
  count = var.memcached_create ? 1 : 0

  description       = "allow to ipv4 0.0.0.0/0"
  security_group_id = aws_security_group.memcached.0.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}

data "aws_iam_policy_document" "sm_app_secret_access" {
  statement {
    sid    = "AllowCredentialsAccessForApplication"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        module.ecs.services[var.service_name].task_exec_iam_role_arn,
      ]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret" "sm_environment_variables" {
  count = var.create_secret_manager ? 1 : 0

  name        = "/raketech/${var.environment}/${var.service_name}/environment-variables"
  description = "Environment variables for ${var.environment} ${var.service_name}"

  recovery_window_in_days = var.environment == "dev" ? 0 : 14 # protect outside of dev
}

resource "aws_secretsmanager_secret_policy" "sm_environment_variables_access" {
  count = var.create_secret_manager ? 1 : 0

  secret_arn = aws_secretsmanager_secret.sm_environment_variables.0.arn
  policy     = data.aws_iam_policy_document.sm_app_secret_access.json
}


resource "aws_iam_policy" "s3_access" {
  count       = var.s3_bucket_a_create ? 1 : 0
  name        = "${var.name}-s3-access"
  path        = "/"
  description = "S3 access policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:DeleteObjectVersion",
          "s3:DeleteObject",
          "s3:Put*",
          "s3:Get*",
          "s3:List*"
        ],
        "Resource" = [
          "arn:aws:s3:::${var.s3_bucket_a_name}/*"
        ]
      }
    ]
  })
}
