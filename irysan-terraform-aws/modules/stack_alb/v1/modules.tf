module "constants" {
  source = "../../terraform-constants/v1"
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  #create = var.create_alb && !var.use_existing_alb

  name = var.name

  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  enable_deletion_protection = true
  create_security_group      = false

  security_groups = [aws_security_group.alb.id]

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port     = 443
      protocol = "HTTPS"

      # hack to allow the loadbalancer https listener to be created
      certificate_arn = var.initial_certificate_arn

      fixed_response = {
        content_type = "text/plain"
        message_body = "Not Found"
        status_code  = "404"
      }
    }
  }

}