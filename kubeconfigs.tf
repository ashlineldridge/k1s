locals {
  // General template for defining kubeconfig files
  kubeconfig_template = <<EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority-data: ${base64encode(tls_self_signed_cert.ca.cert_pem)}
        server: $${server}
      name: ${var.cluster_name}
    contexts:
    - context:
        cluster: ${var.cluster_name}
        user: $${user}
      name: default
    current-context: default
    preferences: {}
    users:
    - name: $${user}
      user:
        client-certificate-data: $${user_cert}
        client-key-data: $${user_private_key}
  EOT

  // Local directory that we save kubconfig files to
  kubeconfig_dir = "${path.module}/${var.build_dir}/kubeconfigs"
}

data "template_file" "node_kubeconfig" {
  count = var.node_instance_count

  template = local.kubeconfig_template
  vars = {
    server           = local.kube_api_private_url
    user             = "system:node:node-${count.index}"
    user_cert        = base64encode(tls_locally_signed_cert.node[count.index].cert_pem)
    user_private_key = base64encode(tls_private_key.node[count.index].private_key_pem)
  }
}

data "template_file" "kube_proxy_kubeconfig" {
  template = local.kubeconfig_template
  vars = {
    server           = local.kube_api_private_url
    user             = "system:kube-proxy"
    user_cert        = base64encode(tls_locally_signed_cert.kube_proxy.cert_pem)
    user_private_key = base64encode(tls_private_key.kube_proxy.private_key_pem)
  }
}

data "template_file" "kube_controller_manager_kubeconfig" {
  template = local.kubeconfig_template
  vars = {
    server           = local.kube_api_localhost_url
    user             = "system:kube-controller-manager"
    user_cert        = base64encode(tls_locally_signed_cert.kube_controller_manager.cert_pem)
    user_private_key = base64encode(tls_private_key.kube_controller_manager.private_key_pem)
  }
}

data "template_file" "kube_scheduler_kubeconfig" {
  template = local.kubeconfig_template
  vars = {
    server           = local.kube_api_localhost_url
    user             = "system:kube-scheduler"
    user_cert        = base64encode(tls_locally_signed_cert.kube_scheduler.cert_pem)
    user_private_key = base64encode(tls_private_key.kube_scheduler.private_key_pem)
  }
}

data "template_file" "admin_kubeconfig" {
  template = local.kubeconfig_template
  vars = {
    server           = local.kube_api_localhost_url
    user             = "admin"
    user_cert        = base64encode(tls_locally_signed_cert.admin.cert_pem)
    user_private_key = base64encode(tls_private_key.admin.private_key_pem)
  }
}

resource "local_file" "node_kubeconfig" {
  count = var.node_instance_count

  content         = data.template_file.node_kubeconfig[count.index].rendered
  filename        = "${local.kubeconfig_dir}/node-${count.index}.kubeconfig"
  file_permission = "0600"
}

resource "local_file" "kube_proxy_kubeconfig" {
  content         = data.template_file.kube_proxy_kubeconfig.rendered
  filename        = "${local.kubeconfig_dir}/kube-proxy.kubeconfig"
  file_permission = "0600"
}

resource "local_file" "kube_controller_manager_kubeconfig" {
  content         = data.template_file.kube_controller_manager_kubeconfig.rendered
  filename        = "${local.kubeconfig_dir}/kube-controller-manager.kubeconfig"
  file_permission = "0600"
}

resource "local_file" "kube_scheduler_kubeconfig" {
  content         = data.template_file.kube_scheduler_kubeconfig.rendered
  filename        = "${local.kubeconfig_dir}/kube-scheduler.kubeconfig"
  file_permission = "0600"
}

resource "local_file" "admin_kubeconfig" {
  content         = data.template_file.admin_kubeconfig.rendered
  filename        = "${local.kubeconfig_dir}/admin.kubeconfig"
  file_permission = "0600"
}

resource "local_file" "ca_cert_pem" {
  content         = tls_self_signed_cert.ca.cert_pem
  filename        = "${local.kubeconfig_dir}/ca_cert.pem"
  file_permission = "0600"
}
