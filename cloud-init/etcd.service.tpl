[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${etcd_local_domain_name} \\
  --cert-file=/etc/etcd/kube_api_cert.pem \\
  --key-file=/etc/etcd/kube_api_private_key.pem \\
  --peer-cert-file=/etc/etcd/kube_api_cert.pem \\
  --peer-key-file=/etc/etcd/kube_api_private_key.pem \\
  --trusted-ca-file=/etc/etcd/ca_cert.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca_cert.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${etcd_local_domain_name}:2380 \\
  --listen-peer-urls https://${etcd_local_domain_name}:2380 \\
  --listen-client-urls https://${etcd_local_domain_name}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${etcd_local_domain_name}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${etcd_cluster_spec} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
