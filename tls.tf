locals {
  ecdsa_algorithm = "RSA"
  ecdsa_curve     = "P256"

  ca_cert_validity_hours = 3 * 365 * 24
  ca_cert_allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]

  cert_validity_hours = 1 * 365 * 24
  cert_allowed_uses = [
    "signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]

  // Local directory that we save TLS files to
  tls_dir = "${path.module}/${var.build_dir}/tls"
}

//
// CA certificate material
//

resource "tls_private_key" "ca" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm         = tls_private_key.ca.algorithm
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = local.ca_cert_validity_hours

  subject {
    common_name         = "Kubernetes"
    country             = "US"
    locality            = "Portland"
    organization        = "Kubernetes"
    organizational_unit = "CA"
    province            = "Oregon"
  }

  allowed_uses = local.ca_cert_allowed_uses
}

//
// Admin user certificate material
//

resource "tls_private_key" "admin" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "admin" {
  key_algorithm   = tls_private_key.admin.algorithm
  private_key_pem = tls_private_key.admin.private_key_pem

  subject {
    common_name         = "admin"
    country             = "US"
    locality            = "Portland"
    organization        = "system:masters"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"

  }
}

resource "tls_locally_signed_cert" "admin" {
  cert_request_pem   = tls_cert_request.admin.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}

//
// Kubelet (per-worker) certificate material
//

resource "tls_private_key" "worker" {
  count = var.worker_instance_count

  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "worker" {
  count = var.worker_instance_count

  key_algorithm   = tls_private_key.worker[count.index].algorithm
  private_key_pem = tls_private_key.worker[count.index].private_key_pem

  // DNS SANs
  dns_names = ["worker-${count.index}"]

  // IP SANs
  ip_addresses = [local.worker_ips[count.index]]

  subject {
    common_name         = "system:node:worker-${count.index}"
    country             = "US"
    locality            = "Portland"
    organization        = "system:nodes"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"
  }
}

resource "tls_locally_signed_cert" "worker" {
  count = var.worker_instance_count

  cert_request_pem   = tls_cert_request.worker[count.index].cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}

//
// Kube Controller Manager certificate material
//

resource "tls_private_key" "kube_controller_manager" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "kube_controller_manager" {
  key_algorithm   = tls_private_key.kube_controller_manager.algorithm
  private_key_pem = tls_private_key.kube_controller_manager.private_key_pem

  subject {
    common_name         = "system:kube-controller-manager"
    country             = "US"
    locality            = "Portland"
    organization        = "system:kube-controller-manager"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"
  }
}

resource "tls_locally_signed_cert" "kube_controller_manager" {
  cert_request_pem   = tls_cert_request.kube_controller_manager.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}

//
// Kube Proxy certificate material
//

resource "tls_private_key" "kube_proxy" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "kube_proxy" {
  key_algorithm   = tls_private_key.kube_proxy.algorithm
  private_key_pem = tls_private_key.kube_proxy.private_key_pem

  subject {
    common_name         = "system:kube-proxy"
    country             = "US"
    locality            = "Portland"
    organization        = "system:node-proxier"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"
  }
}

resource "tls_locally_signed_cert" "kube_proxy" {
  cert_request_pem   = tls_cert_request.kube_proxy.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}

//
// Kube Scheduler certificate material
//

resource "tls_private_key" "kube_scheduler" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "kube_scheduler" {
  key_algorithm   = tls_private_key.kube_scheduler.algorithm
  private_key_pem = tls_private_key.kube_scheduler.private_key_pem

  subject {
    common_name         = "system:kube-scheduler"
    country             = "US"
    locality            = "Portland"
    organization        = "system:node-scheduler"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"
  }
}

resource "tls_locally_signed_cert" "kube_scheduler" {
  cert_request_pem   = tls_cert_request.kube_scheduler.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}

//
// Kubernetes API server certificate material
//

resource "tls_private_key" "kube_api" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "kube_api" {
  key_algorithm   = tls_private_key.kube_api.algorithm
  private_key_pem = tls_private_key.kube_api.private_key_pem

  // DNS SANs
  dns_names = [
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local",
    "kubernetes.svc.cluster.local",
    // Private domain name of the private NLB
    local.kube_api_private_domain,
  ]

  // IP SANs
  ip_addresses = concat([
    "127.0.0.1",
    // The Kubernetes API server is automatically assigned the kubernetes internal
    // DNS name, which will be linked to the first (i.e., after the zeroth) IP address
    // from the cluster service address range.
    cidrhost(var.cluster_service_cidr_block, 1),
  ], local.master_ips)

  subject {
    common_name         = "Kubernetes"
    country             = "US"
    locality            = "Portland"
    organization        = "Kubernetes"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"
  }
}

resource "tls_locally_signed_cert" "kube_api" {
  cert_request_pem   = tls_cert_request.kube_api.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}

//
// Service Account certificate material (used by kube-controller-manager -
// described here: https://kubernetes.io/docs/admin/service-accounts-admin/)
//

resource "tls_private_key" "service_account" {
  algorithm   = local.ecdsa_algorithm
  ecdsa_curve = local.ecdsa_curve
}

resource "tls_cert_request" "service_account" {
  key_algorithm   = tls_private_key.service_account.algorithm
  private_key_pem = tls_private_key.service_account.private_key_pem

  subject {
    common_name         = "service-accounts"
    country             = "US"
    locality            = "Portland"
    organization        = "Kubernetes"
    organizational_unit = "Kubernetes the Hard Way"
    province            = "Oregon"
  }
}

resource "tls_locally_signed_cert" "service_account" {
  cert_request_pem   = tls_cert_request.service_account.cert_request_pem
  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = local.cert_validity_hours
  allowed_uses          = local.cert_allowed_uses
}
