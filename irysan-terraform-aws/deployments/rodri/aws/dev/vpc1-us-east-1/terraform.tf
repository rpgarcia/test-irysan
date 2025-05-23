terraform {
  required_version = ">= 1.7.4"

  backend "s3" {
    bucket         = "rodri-terraform-states"
    key            = "rodri-terraform/rodri-dev-vpc1.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rodri-terraform"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.3"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      "rt:iac:tool"         = "terraform"
      "rt:iac:code"         = "https://gitlab.com/rodri/devops/aws-terraform/rodri-infra/-/tree/main/deployments/rodri/aws/dev/vpc1-us-east-1"
      "rt:iac:code:version" = "not applicable"
      "rt:shared"           = "true"
      "rt:environment"      = "rodri-aws-dev-vpc1-us-east-1"
    }
  }
}

data "terraform_remote_state" "bootstrap_state" {
    backend = "s3" 
    config = {
        bucket         = "rodri-dev-terraform-states"
        key            = "rodri-terraform/rodri_dev_bootstrap.tfstate"
        region         = "us-east-1"
        dynamodb_table = "rodri-terraform"
        encrypt        = true
    }
}
