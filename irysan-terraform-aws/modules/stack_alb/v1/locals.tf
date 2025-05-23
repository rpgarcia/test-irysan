locals {
  ports = [
    80,
    443
  ]
  cloudflare_ips = {
    ipv4 = module.constants.cloudflare_ipv4_ips
    ipv6 = module.constants.cloudflare_ipv6_ips
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
}


