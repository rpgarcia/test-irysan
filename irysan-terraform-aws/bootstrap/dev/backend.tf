terraform {
  # backend "local" {
  #   path = "rodri_bootstrap_local.tfstate"
  # }

  backend "s3" {
    bucket         = "rodri-terraform-states"
    key            = "rodri-terraform/rodri_dev_bootstrap.tfstate"
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

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket            = local.bucket_state
}

resource "aws_s3_bucket_ownership_controls" "terraform_state_bucket_control" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_access_block" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "terraform_state_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.terraform_state_bucket_control,
    aws_s3_bucket_public_access_block.terraform_state_bucket_access_block,
  ]

  bucket = aws_s3_bucket.terraform_state_bucket.id
  acl    = "private"
}

resource "aws_dynamodb_table" "terraform_lock_table" {
  name         = "rodri-terraform"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }
}

