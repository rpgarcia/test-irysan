locals {
    defaults       = file("../default/default_vars.yml")
    environment_path = "./default_vars.yml"
    environment_variables = fileexists(local.environment_path) ? file(local.environment_path) : yamlencode({})
    
    settings = merge(
        yamldecode(local.defaults),
        yamldecode(local.environment_variables)
    )

    organization_name = local.settings.organization
    project_name      = "${local.settings.organization}-aws-${local.settings.environment}"
    environment       = local.settings.environment
    bucket_state      = "rodri-${local.environment}-terraform-states"
    
    tags = {
        "iac:tool"    = "terraform"
        "account"     = local.settings.environment
        "environment" = local.settings.environment
        "terraformed" = "yes"
    }
}

provider "aws" {
  region              = "us-east-1"

  default_tags {
    tags = local.tags
  }
}