resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastion_instance_type
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data = <<-EOF
    #!/usr/bin/env bash
    yum update -y \
      https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum-config-manager --enable epel
    yum install -y tinyproxy
    amazon-linux-extras install docker
    usermod -a -G docker ec2-user
    systemctl restart amazon-ssm-agent
    systemctl start docker
    systemctl start tinyproxy
  EOF

  tags = merge(local.common_tags, {
    "Name" = "${local.cluster_id}-bastion"
  })

  depends_on = [module.vpc]
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

resource "aws_security_group" "bastion" {
  name   = "${local.cluster_id}-bastion"
  vpc_id = module.vpc.vpc_id
  tags   = local.common_tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [module.vpc]
}

data "aws_iam_policy_document" "bastion" {
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

resource "aws_iam_role" "bastion" {
  name                  = "${local.cluster_id}-bastion"
  description           = "Bastion role for ${local.cluster_id}"
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume.json
  force_detach_policies = true
  tags                  = local.common_tags
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

resource "aws_iam_role_policy" "bastion" {
  policy = data.aws_iam_policy_document.bastion.json
  role   = aws_iam_role.bastion.name
}

resource "aws_iam_instance_profile" "bastion" {
  role = aws_iam_role.bastion.name
}
