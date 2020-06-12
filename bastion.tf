resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.bastion_instance_type
  subnet_id              = local.private_subnet
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name

  user_data_base64 = filebase64("${path.module}/scripts/user-data/bastion.sh")

  tags = merge(local.common_tags, {
    "Name" = "${local.cluster_id}-bastion"
  })

  depends_on = [module.vpc]
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

resource "aws_iam_role" "bastion" {
  name                  = "${local.cluster_id}-bastion"
  description           = "Bastion role for ${local.cluster_id}"
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume.json
  force_detach_policies = true
  tags                  = local.common_tags
}

resource "aws_iam_role_policy" "bastion_session_manager" {
  policy = data.aws_iam_policy_document.session_manager.json
  role   = aws_iam_role.bastion.name
}

resource "aws_iam_instance_profile" "bastion" {
  role = aws_iam_role.bastion.name
}
