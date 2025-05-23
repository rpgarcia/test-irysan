output "http_listener_arn" {
  value = var.use_existing_alb ? var.existing_alb_http_listener_arn : module.alb.listeners["http"].arn
}

output "https_listener_arn" {
  value = var.use_existing_alb ? var.existing_alb_https_listener_arn : module.alb.listeners["https"].arn
}

output "alb_security_group_id" {
  value = var.use_existing_alb ? var.existing_alb_security_group_id : module.alb.security_group_id
}

