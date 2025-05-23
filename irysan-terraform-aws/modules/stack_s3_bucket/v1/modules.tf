module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  create_bucket = var.s3_bucket_a_create

  bucket = var.s3_bucket_a_name
  acl    = "null"

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    status     = true
    mfa_delete = false
  }

  attach_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = length(var.s3_bucket_a_policy_statements) > 0 ? var.s3_bucket_a_policy_statements : [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.s3_bucket_a_name}/*"
      }
    ]
  })
}