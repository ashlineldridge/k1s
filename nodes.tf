resource "aws_instance" "node" {
  count = var.node_instance_count

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.node_instance_type
  subnet_id              = local.private_subnet
  vpc_security_group_ids = [aws_security_group.node.id]
  iam_instance_profile   = aws_iam_instance_profile.node.name

  user_data_base64 = base64encode(templatefile("${path.module}/scripts/user-data/node.sh", {
    domain_name          = local.node_domain_names[count.index]
    ca_cert_pem          = tls_self_signed_cert.ca.cert_pem
    node_cert_pem        = tls_locally_signed_cert.node[count.index].cert_pem
    node_private_key_pem = tls_private_key.node[count.index].private_key_pem
  }))

  tags = merge(local.common_tags, {
    "Name" = "${local.cluster_id}-node-${count.index}"
  })

  depends_on = [module.vpc]
}

resource "aws_security_group" "node" {
  name   = "${local.cluster_id}-node"
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

resource "aws_iam_role" "node" {
  name                  = "${local.cluster_id}-node"
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume.json
  force_detach_policies = true
  tags                  = local.common_tags
}

resource "aws_iam_role_policy" "node_session_manager" {
  policy = data.aws_iam_policy_document.session_manager.json
  role   = aws_iam_role.node.name
}

resource "aws_iam_instance_profile" "node" {
  role = aws_iam_role.node.name
}


