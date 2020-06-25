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

data "template_cloudinit_config" "master" {
  count = var.master_instance_count

  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/master/cloud-config.yaml", {
      ca_private_key_pem                     = base64encode(tls_private_key.ca.private_key_pem)
      ca_cert_pem                            = base64encode(tls_self_signed_cert.ca.cert_pem)
      kube_api_private_key_pem               = base64encode(tls_private_key.kube_api.private_key_pem)
      kube_api_cert_pem                      = base64encode(tls_locally_signed_cert.kube_api.cert_pem)
      service_account_private_key_pem        = base64encode(tls_private_key.service_account.private_key_pem)
      service_account_cert_pem               = base64encode(tls_locally_signed_cert.service_account.cert_pem)
      encryption_config                      = base64encode(data.template_file.encryption_config.rendered)
      kube_scheduler_config                  = filebase64("${path.module}/cloud-init/master/kube-scheduler.yaml")
      kube_controller_manager_kubeconfig     = base64encode(data.template_file.kube_controller_manager_kubeconfig.rendered)
      kube_scheduler_kubeconfig              = base64encode(data.template_file.kube_scheduler_kubeconfig.rendered)
      admin_kubeconfig                       = base64encode(data.template_file.admin_kubeconfig.rendered)
      etcd_service_config                    = base64encode(data.template_file.etcd_service_config[count.index].rendered)
      kube_api_service_config                = base64encode(data.template_file.kube_api_service_config[count.index].rendered)
      kube_controller_manager_service_config = base64encode(data.template_file.kube_controller_manager_service_config[count.index].rendered)
      kube_scheduler_service_config          = filebase64("${path.module}/cloud-init/master/kube-scheduler.service")
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/cloud-init/master/install.sh")
  }
}

data "template_file" "etcd_service_config" {
  count = var.master_instance_count

  template = file("${path.module}/cloud-init/master/etcd.service")
  vars = {
    name                        = "master-${count.index}"
    initial_advertise_peer_urls = "https://${local.master_ips[count.index]}:2380"
    listen_peer_urls            = "https://${local.master_ips[count.index]}:2380"
    listen_client_urls          = "https://${local.master_ips[count.index]}:2379,https://127.0.0.1:2379"
    advertise_client_urls       = "https://${local.master_ips[count.index]}:2379"
    initial_cluster             = join(",", [for i, ip in local.master_ips : "master-${i}=https://${ip}:2380"])
  }
}

data "template_file" "kube_api_service_config" {
  count = var.master_instance_count

  template = file("${path.module}/cloud-init/master/kube-apiserver.service")
  vars = {
    advertise_address        = local.master_ips[count.index]
    etcd_servers             = join(",", [for i, ip in local.master_ips : "https://${ip}:2379"])
    service_cluster_ip_range = var.cluster_service_cidr_block
  }
}

data "template_file" "kube_controller_manager_service_config" {
  count = var.master_instance_count

  template = file("${path.module}/cloud-init/master/kube-controller-manager.service")
  vars = {
    cluster_cidr             = var.cluster_pod_cidr_block
    service_cluster_ip_range = var.cluster_service_cidr_block
  }
}

resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

data "template_file" "encryption_config" {
  template = file("${path.module}/cloud-init/master/encryption.yaml")
  vars = {
    encryption_key = base64encode(random_password.encryption_key.result)
  }
}
