#!/usr/bin/env bash

set -eou pipefail

etcd_version='v3.4.9'

mkdir -p /boot
curl -Lo etcd.tar.gz \
  "https://github.com/etcd-io/etcd/releases/download/${etcd_version}/etcd-${etcd_version}-linux-amd64.tar.gz"
tar zxf etcd.tar.gz
mv "etcd-${etcd_version}-linux-amd64"/etcd* /usr/local/bin/

