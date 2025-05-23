locals {
  name = "dev-irysan-com" # "name" cannot be longer than 32 characters

  container_name = "irysan-com"
  container_port = 80
  environment    = "dev"

  domain_name = "dev.irysan.com"
  arn_ecr_image     = "xxxxxxx.dkr.ecr.us-east-1.amazonaws.com"
}

data "terraform_remote_state" "vpc1" {
  backend = "remote"

  config = {
    organization = "rodri"
    workspaces = {
      name = "rodri-aws-dev-vpc1-us-east-1"
    }
  }
}

data "terraform_remote_state" "alb1" {
  backend = "remote"

  config = {
    organization = "rodri"
    workspaces = {
      name = "rodri-aws-dev-alb1"
    }
  }
}

module "root_module" {
  source = "./modules/stack_service/v1"

  name        = local.name
  environment = local.environment

  domain_name = local.domain_name

  vpc_id          = data.terraform_remote_state.vpc1.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc1.outputs.private_subnets
  public_subnets  = data.terraform_remote_state.vpc1.outputs.public_subnets
  vpc_cidr_block  = data.terraform_remote_state.vpc1.outputs.vpc_cidr_block

  service_name      = local.name
  container_name    = local.container_name
  container_port    = local.container_port
  healthcheck_path = "/"

  cpu_task = 2048
  memory_task = 4096

  container_definitions = {
    (local.container_name) = {
      cpu       = 2048
      memory    = 4096
      essential = true
      #image     = "${local.arn_ecr_image}/irysan.com-newbuild:634d6763-development"
      image     = "nginx"
      # user      = "33"

      enable_autoscaling = false

      port_mappings = [
        {
          name          = local.container_name
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]

      readonly_root_filesystem = false
      environment = []
      secrets     = []
    }
  }

  use_existing_alb                = true
  existing_alb_https_listener_arn = data.terraform_remote_state.alb1.outputs.https_listener_arn
  existing_alb_http_listener_arn  = data.terraform_remote_state.alb1.outputs.http_listener_arn
  existing_alb_security_group_id  = data.terraform_remote_state.alb1.outputs.alb_security_group_id
  alb_listener_rule_priority      = 1

  s3_bucket_a_create = true
  s3_bucket_a_name = "s3.${local.domain_name}"
  s3_bucket_a_versioning            = true 
}
