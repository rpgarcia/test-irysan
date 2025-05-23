locals {
  ports = [
    80,
    443
  ]
  cloudflare_ips = {
    ipv4 = [
      "173.245.48.0/20",
      "103.21.244.0/22",
      "103.22.200.0/22",
      "103.31.4.0/22",
      "141.101.64.0/18",
      "108.162.192.0/18",
      "190.93.240.0/20",
      "188.114.96.0/20",
      "197.234.240.0/22",
      "198.41.128.0/17",
      "162.158.0.0/15",
      "104.16.0.0/13",
      "104.24.0.0/14",
      "172.64.0.0/13",
      "131.0.72.0/22",
    ]
    ipv6 = [
      "2400:cb00::/32",
      "2606:4700::/32",
      "2803:f800::/32",
      "2405:b500::/32",
      "2405:8100::/32",
      "2a06:98c0::/29",
      "2c0f:f248::/32",
    ]
  }
  cloudflare_ingress_ipv4 = distinct(flatten([
    for port in local.ports : [
      for ip in local.cloudflare_ips.ipv4 : {
        ip   = ip
        port = port
      }

    ]
  ]))
  cloudflare_ingress_ipv6 = distinct(flatten([
    for port in local.ports : [
      for ip in local.cloudflare_ips.ipv6 : {
        ip   = ip
        port = port
      }

    ]
  ]))
  db_vpc_security_group_ids    = var.create_db ? concat(var.db_vpc_security_group_ids, [aws_security_group.rds.0.id]) : []
  redis_vpc_security_group_ids = var.redis_create ? concat(var.redis_vpc_security_group_ids, [aws_security_group.redis.*.id]) : []

  tasks_iam_role_policies = merge(
    { ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess" },
    var.s3_bucket_a_create ? { S3Access = aws_iam_policy.s3_access[0].arn } : {}
  )

  opsgenie_keys = {
    P1 = var.opsgenie_key_p1
    P2 = var.opsgenie_key_p2
    P3 = var.opsgenie_key_p3
  }

  opsgenie_key = lookup(local.opsgenie_keys, var.alarms_priority)

  all_domains = (contains(var.subject_alternative_names, var.domain_name) == false ? concat(var.subject_alternative_names, [var.domain_name]) : var.subject_alternative_names)

  memcached_az_mode           = "single-az"
  memcached_apply_immediately = false
  memcached_port              = 11211

  db_port_auto = {
    "postgres"   = "5432"
    "postgresql" = "5432"
    "mysql"      = "3306"
    "mariadb"    = "3306"
  }

  db_username = {
    "postgres"   = "pgadmin"
    "postgresql" = "pgadmin"
    "mysql"      = "admin"
    "mariadb"    = "admin"
  }
}
