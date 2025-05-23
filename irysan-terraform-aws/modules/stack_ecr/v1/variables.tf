variable "repository_name" {
    description = "ECR repository name"
    type        = string
}

variable "repository_read_write_access_arns" {
  description = "list of iam arn or arn of account using format arn:aws:iam::012345678901:root"
  type = list(string)
}

variable "repository_image_tag_mutability" {
  type = string
  default = "MUTABLE"
}

variable "repository_image_scan_on_push" {
  type = bool
  default = true
}

variable "create_lifecycle_policy" {
  type = bool
  default = false
}

variable "repository_lifecycle_policy" {
  type = map
  default = {
    rules = []
  }
}