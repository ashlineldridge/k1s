locals {
  // Cluster identifier that is unique across regions
  cluster_id = "${var.cluster_name}-${var.region}"

  // Common tags to be applied to all taggable resources
  common_tags = {
    cluster-name   = var.cluster_name
    cluster-region = var.region
  }

  // Common autoscaling group tags which need to be specified in a different format
  common_asg_tags = [
    for k, v in local.common_tags : {
      key                 = k
      value               = v
      propagate_at_launch = true
    }
  ]
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

