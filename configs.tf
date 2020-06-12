locals {
  // Regex for extracting certificate/key body from pem file content
  pem_extract = "(?s)-\n(.*)\n-"

  // Extract CA certificate body
  ca_cert = replace(regex(local.pem_extract, tls_self_signed_cert.ca.cert_pem)[0], "\n", "")

  // General template for defining kubeconfig files
  config_template = <<EOF
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority-data: ${local.ca_cert}
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
  EOF

}

data "template_file" "node_config" {
  count = var.node_instance_count

  template = local.config_template
  vars = {
    server           = local.kube_api_url
    user             = "system:node:node-${count.index}"
    user_cert        = replace(regex(local.pem_extract, tls_locally_signed_cert.node[count.index].cert_pem)[0], "\n", "")
    user_private_key = replace(regex(local.pem_extract, tls_private_key.node[count.index].private_key_pem)[0], "\n", "")
  }
}

data "template_file" "kube_proxy_config" {
  template = local.config_template
  vars = {
    server           = local.kube_api_url
    user             = "system:kube-proxy"
    user_cert        = replace(regex(local.pem_extract, tls_locally_signed_cert.kube_proxy.cert_pem)[0], "\n", "")
    user_private_key = replace(regex(local.pem_extract, tls_private_key.kube_proxy.private_key_pem)[0], "\n", "")
  }
}

data "template_file" "kube_controller_manager_config" {
  template = local.config_template
  vars = {
    server           = local.kube_api_local_url
    user             = "system:kube-controller-manager"
    user_cert        = replace(regex(local.pem_extract, tls_locally_signed_cert.kube_controller_manager.cert_pem)[0], "\n", "")
    user_private_key = replace(regex(local.pem_extract, tls_private_key.kube_controller_manager.private_key_pem)[0], "\n", "")
  }
}

data "template_file" "kube_scheduler_config" {
  template = local.config_template
  vars = {
    server           = local.kube_api_local_url
    user             = "system:kube-scheduler"
    user_cert        = replace(regex(local.pem_extract, tls_locally_signed_cert.kube_scheduler.cert_pem)[0], "\n", "")
    user_private_key = replace(regex(local.pem_extract, tls_private_key.kube_scheduler.private_key_pem)[0], "\n", "")
  }
}

data "template_file" "admin_config" {
  template = local.config_template
  vars = {
    server           = local.kube_api_local_url
    user             = "admin"
    user_cert        = replace(regex(local.pem_extract, tls_locally_signed_cert.admin.cert_pem)[0], "\n", "")
    user_private_key = replace(regex(local.pem_extract, tls_private_key.admin.private_key_pem)[0], "\n", "")
  }
}
