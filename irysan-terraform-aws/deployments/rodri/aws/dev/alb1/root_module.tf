data "terraform_remote_state" "vpc1" {
  backend = "remote"

  config = {
    organization = "rodri"
    workspaces = {
      name = "rodri-aws-dev-vpc1-us-east-1"
    }
  }
}

module "root_module" {
  source = "./modules/stack_alb/v1"

  name = "rodri-aws-dev-alb1"

  vpc_id         = data.terraform_remote_state.vpc1.outputs.vpc_id
  public_subnets = data.terraform_remote_state.vpc1.outputs.public_subnets

  initial_certificate_arn = "arn:aws:acm:us-east-1:xxxxxx:certificate/xxxxxx"

}

output "http_listener_arn" {
  value = module.root_module.http_listener_arn
}

output "https_listener_arn" {
  value = module.root_module.https_listener_arn
}

output "alb_security_group_id" {
  value = module.root_module.alb_security_group_id
}

output "alb_dns_name" {
  value = module.root_module.alb_dns_name
}