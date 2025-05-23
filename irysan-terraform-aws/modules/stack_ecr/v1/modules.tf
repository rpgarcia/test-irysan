module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = var.repository_name
  repository_image_tag_mutability = var.repository_image_tag_mutability
  repository_image_scan_on_push = var.repository_image_scan_on_push

  repository_read_write_access_arns = var.repository_read_write_access_arns
  create_lifecycle_policy = var.create_lifecycle_policy
  repository_lifecycle_policy =  jsonencode(var.repository_lifecycle_policy)

}