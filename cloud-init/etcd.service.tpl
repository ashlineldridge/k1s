[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \
  --name ${name} \
  --cert-file=/etc/etcd/kube_api_cert.pem \
  --key-file=/etc/etcd/kube_api_private_key.pem \
  --peer-cert-file=/etc/etcd/kube_api_cert.pem \
  --peer-key-file=/etc/etcd/kube_api_private_key.pem \
  --trusted-ca-file=/etc/etcd/ca_cert.pem \
  --peer-trusted-ca-file=/etc/etcd/ca_cert.pem \
  --peer-client-cert-auth \
  --client-cert-auth \
  --initial-advertise-peer-urls ${initial_advertise_peer_urls} \
  --listen-peer-urls ${listen_peer_urls} \
  --listen-client-urls ${listen_client_urls} \
  --advertise-client-urls ${advertise_client_urls} \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster ${initial_cluster} \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
