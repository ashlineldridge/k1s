resource "aws_instance" "master" {
  count = var.master_instance_count

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.master_instance_type
  subnet_id              = local.private_subnet
  vpc_security_group_ids = [aws_security_group.master.id]
  iam_instance_profile   = aws_iam_instance_profile.master.name

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/user-data/master.sh", {
    domain_name                     = local.master_domain_names[count.index]
    ca_cert_pem                     = tls_self_signed_cert.ca.cert_pem
    ca_private_key_pem              = tls_private_key.ca.private_key_pem
    kube_api_cert_pem               = tls_locally_signed_cert.kube_api.cert_pem
    kube_api_private_key_pem        = tls_private_key.kube_api.private_key_pem
    service_account_cert_pem        = tls_locally_signed_cert.service_account.cert_pem
    service_account_private_key_pem = tls_private_key.service_account.private_key_pem
  }))

  tags = merge(local.common_tags, {
    "Name" = "${local.cluster_id}-master-${count.index}"
  })

  depends_on = [module.vpc]
}

resource "aws_security_group" "master" {
  name   = "${local.cluster_id}-master"
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

resource "aws_iam_role" "master" {
  name                  = "${local.cluster_id}-master"
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume.json
  force_detach_policies = true
  tags                  = local.common_tags
}

resource "aws_iam_role_policy" "master_session_manager" {
  policy = data.aws_iam_policy_document.session_manager.json
  role   = aws_iam_role.master.name
}

resource "aws_iam_instance_profile" "master" {
  role = aws_iam_role.master.name
}
