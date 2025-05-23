output "http_listener_arn" {
  value = module.alb.listeners["http"].arn
}

output "https_listener_arn" {
  value = module.alb.listeners["https"].arn
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "alb_dns_name" {
  value = module.alb.dns_name
}
