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

  master_ips = [for i in range(var.master_instance_count) : cidrhost(var.private_subnet_cidr_blocks[0], 10 + i)]
  node_ips   = [for i in range(var.master_instance_count) : cidrhost(var.private_subnet_cidr_blocks[0], 20 + i)]

  // Name of the Route53 private zone
  zone_name = "${local.cluster_id}.local"

  // Private domain names of the cluster instances
  node_domain_names   = [for i in range(var.node_instance_count) : "node-${i}.${local.zone_name}"]
  master_domain_names = [for i in range(var.master_instance_count) : "master-${i}.${local.zone_name}"]
  etcd_domain_names   = [for i in range(var.master_instance_count) : "etcd-${i}.${local.zone_name}"]

  // Private domain name and URLs of the API load balancer
  kube_api_domain_name = "kube-api.${local.zone_name}"
  kube_api_port        = 6443
  kube_api_url         = "https://${local.kube_api_domain_name}:${local.kube_api_port}"
  kube_api_local_url   = "https://127.0.0.1:${local.kube_api_port}"
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

