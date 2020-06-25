#!/usr/bin/env bash

set -eou pipefail

kubernetes_version='v1.15.3'
kubernetes_release_url="https://storage.googleapis.com/kubernetes-release/release/${kubernetes_version}"
etcd_version='v3.4.9'

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
