variable "create_bucket" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = true
}

variable "bucket" {
  description = "(Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = null
}

variable "s3_bucket_a_policy_statements" {
  description = "List of policy statements for the s3 bucket"
  type = list(object({
    Effect = string
    Principal = any
    Action   = string
    Resource = string
  }))
  default = []
}

variable "s3_bucket_a_create" {
  description = "Controls if S3 bucket should be created"
  type        = bool
  default     = false
}

variable "s3_bucket_a_name" {
  description = "(Optional, Forces new resource) The name of the bucket. If omitted, Terraform will assign a random, unique name."
  type        = string
  default     = ""
}