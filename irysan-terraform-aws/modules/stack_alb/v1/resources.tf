resource "aws_security_group" "alb" {
  name        = "alb-${var.name}"
  description = "Security group for ${var.name} application load balancer"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_ipv4_ingress_rules" {
  for_each          = { for entry in local.cloudflare_ingress_ipv4 : "${entry.port}.${entry.ip}" => entry }
  description       = "allow from ipv4 ${each.value.ip} on port ${each.value.port}"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = each.value.ip
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_ipv6_ingress_rules" {
  for_each          = { for entry in local.cloudflare_ingress_ipv6 : "${entry.port}.${entry.ip}" => entry }
  description       = "allow from ipv6 ${each.value.ip} on port ${each.value.port}"
  security_group_id = aws_security_group.alb.id
  cidr_ipv6         = each.value.ip
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_ipv4_ingress_rules" {
  description       = "allow to ipv4 0.0.0.0/0"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}

resource "aws_vpc_security_group_egress_rule" "alb_ipv6_ingress_rules" {
  description       = "allow to ipv6 ::0/0"
  security_group_id = aws_security_group.alb.id
  cidr_ipv6         = "::/0"
  from_port         = -1
  to_port           = -1
  ip_protocol       = -1
}

