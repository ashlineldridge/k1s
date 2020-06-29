resource "aws_instance" "master" {
  count = var.master_instance_count

  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.master_instance_type
  subnet_id              = local.private_subnet
  vpc_security_group_ids = [aws_security_group.master.id]
  iam_instance_profile   = aws_iam_instance_profile.master.name
  private_ip             = local.master_ips[count.index]

  user_data_base64 = data.template_cloudinit_config.master[count.index].rendered

  tags = merge(local.common_tags, {
    "Name" = "${local.cluster_id}-master-${count.index}"
  })

  depends_on = [module.vpc, aws_s3_bucket_object.master_files]
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

data "template_cloudinit_config" "master" {
  count = var.master_instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<EOT
      #!/usr/bin/env bash
      mkdir -p /etc/boot
      echo "${local.master_files_checksum}" > /etc/boot/files.md5
      echo "${count.index}" > /etc/boot/id
      echo "${aws_s3_bucket.cloud_init.id}" > /etc/boot/bucket
    EOT
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/cloud-init/master/init.sh")
  }
}
