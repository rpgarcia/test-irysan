terraform {
  required_version = ">= 1.7.4"

  backend "s3" {
    bucket         = "rodri-terraform-states"
    key            = "rodri-terraform/rodri-dev-irysan-com.tfstate"
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
      "rt:iac:code"         = "https://gitlab.com/rodri/devops/aws-terraform/rodri-infra/-/tree/main/deployments/rodri/aws/dev/irysan-com"
      "rt:iac:code:version" = "not applicable"
      "rt:shared"           = "false"
      "rt:environment"      = "rodri-aws-dev-irysan-com"
    }
  }
}