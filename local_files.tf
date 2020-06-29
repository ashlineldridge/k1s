//
// Local TLS files
//

resource "local_file" "ca_cert_pem" {
  content         = tls_self_signed_cert.ca.cert_pem
  filename        = "${local.tls_dir}/ca-cert.pem"
  file_permission = "0600"
}

resource "local_file" "admin_cert_pem" {
  content         = tls_locally_signed_cert.admin.cert_pem
  filename        = "${local.tls_dir}/admin-cert.pem"
  file_permission = "0600"
}

resource "local_file" "admin_private_key_pem" {
  content         = tls_private_key.admin.private_key_pem
  filename        = "${local.tls_dir}/admin-private-key.pem"
  file_permission = "0600"
}

//
// Local kubeconfig files
//

resource "local_file" "worker_kubeconfig" {
  count = var.worker_instance_count

  content         = data.template_file.worker_kubeconfig[count.index].rendered
  filename        = "${local.kubeconfig_dir}/worker-${count.index}.kubeconfig"
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
