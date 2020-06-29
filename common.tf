locals {
  // Cluster identifier that is unique across regions
  cluster_id = "${var.cluster_name}-${var.region}"

  // Common tags to be applied to all taggable resources
  common_tags = {
    cluster-name   = var.cluster_name
    cluster-region = var.region
  }

  // For simplicity, we'll just use a single public and private subnet.
  public_subnet  = module.vpc.public_subnets[0]
  private_subnet = module.vpc.private_subnets[0]

  bastion_ip = cidrhost(var.private_subnet_cidr_blocks[0], 4) // 0,1,2,3 are reserved by AWS
  master_ips = [for i in range(var.master_instance_count) : cidrhost(var.private_subnet_cidr_blocks[0], 10 + i)]
  worker_ips = [for i in range(var.master_instance_count) : cidrhost(var.private_subnet_cidr_blocks[0], 20 + i)]

  // Name of the Route53 private zone
  private_zone_name = "${local.cluster_id}.local"

  // Private domain name and URLs of the private API load balancer
  kube_api_private_domain = "kube-api.${local.private_zone_name}"
  kube_api_private_url    = "https://${local.kube_api_private_domain}"
  kube_api_localhost_url  = "https://127.0.0.1:6443"

  // Public domain name for the public API load balancer
  kube_api_public_domain = "${local.cluster_id}.${var.public_zone_name}"
  kube_api_public_url    = "https://${local.kube_api_public_domain}"
}

data "aws_availability_zones" "all" {}

data "aws_iam_policy_document" "session_manager" {
  statement {
    sid = "AllowSessionManager"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "s3:GetEncryptionConfiguration",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    sid     = "AllowEC2AssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Latest Amazon Linux 2 AMI in the region
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

