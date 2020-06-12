#!/usr/bin/env bash

set -eou pipefail

# Variables provided by Terraform
domain_name="${domain_name}"
ca_cert_pem="${ca_cert_pem}"
node_cert_pem="${node_cert_pem}"
node_private_key_pem="${node_private_key_pem}"


echo "$${domain_name}" > ~/hello.txt
echo "$${ca_cert_pem}" > ~/ca_cert.pem
echo "$${node_cert_pem}" > ~/node_cert.pem
echo "$${node_private_key_pem}" > ~/node_private_key.pem
