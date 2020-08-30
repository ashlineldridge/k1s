resource "aws_instance" "worker" {
  count = var.worker_instance_count

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.worker_instance_type
  subnet_id              = local.private_subnet
  vpc_security_group_ids = [aws_security_group.worker.id]
  iam_instance_profile   = aws_iam_instance_profile.worker.name
  private_ip             = local.worker_ips[count.index]

  tags = merge(local.common_tags, {
    "Name" = "${local.cluster_id}-worker-${count.index}"
  })

  depends_on = [module.vpc]
}

resource "aws_security_group" "worker" {
  name   = "${local.cluster_id}-worker"
  vpc_id = module.vpc.vpc_id
  tags   = local.common_tags

  // TODO: Lock down
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  depends_on = [module.vpc]
}

resource "aws_iam_role" "worker" {
  name                  = "${local.cluster_id}-worker"
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume.json
  force_detach_policies = true
  tags                  = local.common_tags
}

resource "aws_iam_role_policy" "worker_session_manager" {
  policy = data.aws_iam_policy_document.session_manager.json
  role   = aws_iam_role.worker.name
}

resource "aws_iam_role_policy" "worker_s3" {
  policy = data.aws_iam_policy_document.worker_s3.json
  role   = aws_iam_role.worker.name
}

resource "aws_iam_instance_profile" "worker" {
  role = aws_iam_role.worker.name
}

data "aws_iam_policy_document" "worker_s3" {
  statement {
    sid       = "AllowListCloudInitBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.cloud_init.arn]
  }
  statement {
    sid       = "AllowGetCloudInitObjects"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.cloud_init.arn}/${local.worker_prefix}/*"]
  }
}


