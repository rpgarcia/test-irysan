module "root_module" {
  source = "./modules/stack_vpc/v1"

  name     = "rodri-aws-dev-vpc1-us-east-1"
  vpc_cidr = "10.101.64.0/19"

  enable_nat_gateway = true
  single_nat_gateway = true
}

output "vpc_id" {
  value = module.root_module.vpc_id
}

output "private_subnets" {
  value = module.root_module.private_subnets
}

output "public_subnets" {
  value = module.root_module.public_subnets
}

output "vpc_cidr_block" {
  value = module.root_module.vpc_cidr_block
}

output "database_subnet_group_name" {
  value = module.root_module.database_subnet_group_name
}

output "database_subnets" {
  value = module.root_module.database_subnets
}

output "elasticache_subnet_group_name" {
  value = module.root_module.elasticache_subnet_group_name
}

output "elasticache_subnets" {
  value = module.root_module.elasticache_subnets
}
