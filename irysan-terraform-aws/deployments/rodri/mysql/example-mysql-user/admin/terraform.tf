terraform {
  required_version = ">= 1.7.1"

  backend "s3" {
    bucket         = "rodri-terraform-states"
    key            = "rodri-terraform/rodri-mysql-webapp-us-east-1-rds-amazonaws-com-admin.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rodri-terraform"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.3"
    }
    mysql = {
      source = "petoju/mysql"
      version = "3.0.57"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "1.4.3"
    }
  }
}

provider "aws" {
  region  = "us-east-1"

  allowed_account_ids = [xxxxxxxxxxxx]
}

data "aws_secretsmanager_secret_version" "mysql_creds" {
  secret_id = "arn:aws:secretsmanager:us-east-1:xxxxxx:secret:rds!db-xxxxxxxxxxx"
}

provider "mysql" {
  endpoint = "webapp.us-east-1.rds.amazonaws.com:3306"
  username = jsondecode(data.aws_secretsmanager_secret_version.mysql_creds.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.mysql_creds.secret_string)["password"]
}

provider "onepassword" {
  account = "rodri.1password.com"
}