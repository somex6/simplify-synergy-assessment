module "vpc" {
  source = "./modules/vpc"

  vpc_name        = var.vpc_name
  vpc_cidr        = var.vpc_cidr
  a_zones         = var.a_zones
  private_subnets = var.private_subnets
  tags            = var.tags
}