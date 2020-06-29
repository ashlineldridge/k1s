#!/usr/bin/env bash

set -eou pipefail

id="$(cat /etc/boot/id)"
bucket="$(cat /etc/boot/bucket)"
kubernetes_version='v1.15.3'
kubernetes_release_url="https://storage.googleapis.com/kubernetes-release/release/${kubernetes_version}"
etcd_version='v3.4.9'

mkdir -p /var/lib/kubernetes/tls
mkdir -p /var/lib/kubernetes/resources
mkdir -p /var/lib/kubernetes/kubeconfigs

# Download TLS files
aws s3 cp --recursive "s3://${bucket}/master/tls" /var/lib/kubernetes/tls

# Download TLS files
aws s3 cp --recursive "s3://${bucket}/master/resources" /var/lib/kubernetes/resources

# Download kubeconfig files
aws s3 cp --recursive "s3://${bucket}/master/kubeconfigs" /var/lib/kubernetes/kubeconfigs

# Download systemd files
aws s3 cp "s3://${bucket}/master/systemd/etcd-${id}.service" /etc/systemd/system/etcd.service
aws s3 cp "s3://${bucket}/master/systemd/kube-apiserver-${id}.service" /etc/systemd/system/kube-apiserver.service
aws s3 cp "s3://${bucket}/master/systemd/kube-controller-manager-${id}.service" /etc/systemd/system/kube-controller-manager.service
aws s3 cp "s3://${bucket}/master/systemd/kube-scheduler.service" /etc/systemd/system/kube-scheduler.service

###
### Install etcd
###

cd /tmp
curl -Lo etcd.tar.gz \
  "https://github.com/etcd-io/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"
tar zxf etcd.tar.gz
mv "etcd-${etcd_version}-linux-amd64"/etcd* /usr/local/bin/

###
### Install kube-apiserver
###

curl -Lo /usr/local/bin/kube-apiserver \
  "${kubernetes_release_url}/bin/linux/amd64/kube-apiserver"
chmod +x /usr/local/bin/kube-apiserver

###
### Install kube-controller-manager
###

curl -Lo /usr/local/bin/kube-controller-manager \
  "${kubernetes_release_url}/bin/linux/amd64/kube-controller-manager"
chmod +x /usr/local/bin/kube-controller-manager

###
### Install kube-scheduler
###

curl -Lo /usr/local/bin/kube-scheduler \
  "${kubernetes_release_url}/bin/linux/amd64/kube-scheduler"
chmod +x /usr/local/bin/kube-scheduler

###
### Install kubectl
###

curl -Lo /usr/local/bin/kubectl \
  "${kubernetes_release_url}/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl

###
### Start up the services
###

systemctl daemon-reload
systemctl enable etcd kube-apiserver kube-controller-manager kube-scheduler
systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler

###
### Apply the initial RBAC configuration to provide the API server with kubelet access
###

kubectl apply -f /var/lib/kubernetes/resources/rbac.yaml
