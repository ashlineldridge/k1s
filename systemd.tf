//
// Systemd files (required by masters)
//


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
