// Ideally, we'd just include all files that need to be installed onto the instances
// in a cloud-config write_files block but AWS's 16K user data limit prevents us from
// doing so. As a workaround, we publish the TLS files, kubeconfigs, and resource files
// to a S3 bucket and download them during cloud-init.

locals {
  // S3 prefixes for files downloaded on master instances
  master_prefix             = "master"
  master_tls_prefix         = "${local.master_prefix}/tls"
  master_kubeconfigs_prefix = "${local.master_prefix}/kubeconfigs"
  master_resources_prefix   = "${local.master_prefix}/resources"
  master_systemd_prefix     = "${local.master_prefix}/systemd"

  // S3 prefixes for files downloaded on worker instances
  worker_prefix             = "worker"
  worker_tls_prefix         = "${local.worker_prefix}/tls"
  worker_kubeconfigs_prefix = "${local.worker_prefix}/kubeconfigs"

  // Master files: keys are S3 prefixes, values are file contents
  master_files = merge({
    // TLS files
    "${local.master_tls_prefix}/ca-private-key.pem"              = tls_private_key.ca.private_key_pem
    "${local.master_tls_prefix}/ca-cert.pem"                     = tls_self_signed_cert.ca.cert_pem
    "${local.master_tls_prefix}/kube-api-private-key.pem"        = tls_private_key.kube_api.private_key_pem
    "${local.master_tls_prefix}/kube-api-cert.pem"               = tls_locally_signed_cert.kube_api.cert_pem
    "${local.master_tls_prefix}/service-account-private-key.pem" = tls_private_key.service_account.private_key_pem
    "${local.master_tls_prefix}/service-account-cert.pem"        = tls_locally_signed_cert.service_account.cert_pem

    // Kubeconfig files
    "${local.master_kubeconfigs_prefix}/kube-controller-manager.kubeconfig" = data.template_file.kube_controller_manager_kubeconfig.rendered
    "${local.master_kubeconfigs_prefix}/kube-scheduler.kubeconfig"          = data.template_file.kube_scheduler_kubeconfig.rendered
    "${local.master_kubeconfigs_prefix}/admin.kubeconfig"                   = data.template_file.admin_kubeconfig.rendered

    // Resource files
    "${local.master_resources_prefix}/encryption.yaml"     = data.template_file.encryption_config.rendered
    "${local.master_resources_prefix}/kube-scheduler.yaml" = file("${path.module}/cloud-init/master/kube-scheduler.yaml")
    "${local.master_resources_prefix}/rbac.yaml"           = file("${path.module}/cloud-init/master/rbac.yaml")

    // Systemd files
    "${local.master_systemd_prefix}/kube-scheduler.service" = file("${path.module}/cloud-init/master/kube-scheduler.service")
    },

    // Systemd files that are parameterized
    zipmap([for i in range(var.master_instance_count) : "${local.master_systemd_prefix}/etcd-${i}.service"], data.template_file.etcd_service_config[*].rendered),
    zipmap([for i in range(var.master_instance_count) : "${local.master_systemd_prefix}/kube-apiserver-${i}.service"], data.template_file.kube_api_service_config[*].rendered),
    zipmap([for i in range(var.master_instance_count) : "${local.master_systemd_prefix}/kube-controller-manager-${i}.service"], data.template_file.kube_controller_manager_service_config[*].rendered),
  )

  // Checksum of all uploaded master files
  master_files_checksum = md5(join("", values(local.master_files)))
}

resource "aws_s3_bucket" "cloud_init" {
  bucket        = local.cluster_id
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_object" "master_files" {
  for_each = local.master_files

  bucket  = aws_s3_bucket.cloud_init.id
  key     = each.key
  content = each.value
}
