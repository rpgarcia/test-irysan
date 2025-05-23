output "vpc_cidr" {
    value = local.settings.vpc_cidr
}

output "project_name" {
    value = local.project_name
}

output "default_tags" {
    value = local.tags
}

output "organization" {
    value = local.settings.organization
}

output "region" {
    value = local.settings.region
}

output "account" {
    value = local.settings.account
}

output "environment" {
    value = local.settings.environment
}