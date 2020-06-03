module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.cluster_id
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.all.names
  public_subnets  = var.public_subnet_cidr_blocks
  private_subnets = var.private_subnet_cidr_blocks

  # Enable NAT gateways but only provision one
  enable_nat_gateway = true
  single_nat_gateway = true

  # The following DNS options are required to enable Route53 private zones
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.common_tags
}
