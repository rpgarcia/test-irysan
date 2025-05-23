output "ecs_deploy_role" {
  value = aws_iam_role.deploy_role.name
}

output "ecs_deploy_policy_arn" {
  value = aws_iam_policy.ecs_deploy_policy.arn
}

output "ecr_shared_services_policy_arn" {
  value = aws_iam_policy.ecr_shared_services_policy.arn
}

output "docker_host_deploy_policy_arn" {
  value = aws_iam_policy.docker_host_deploy_policy.arn
}
