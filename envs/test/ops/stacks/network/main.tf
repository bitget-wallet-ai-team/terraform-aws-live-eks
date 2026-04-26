locals {
  name = "bk-openclaw-poc"
}

module "vpc" {
  source = "../../../../../modules/network/vpc"

  name = local.name
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = local.name
  }
}
