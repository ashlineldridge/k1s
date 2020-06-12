#!/usr/bin/env bash

set -eou pipefail

# Variables provided by Terraform
domain_name="${domain_name}"
ca_cert_pem="${ca_cert_pem}"
ca_private_key_pem="${ca_private_key_pem}"
kube_api_cert_pem="${kube_api_cert_pem}"
kube_api_private_key_pem="${kube_api_private_key_pem}"
service_account_cert_pem="${service_account_cert_pem}"
service_account_private_key_pem="${service_account_private_key_pem}"

echo "$${domain_name}" > ~/hello.txt
echo "$${ca_cert_pem}" > ~/ca_cert.pem
echo "$${ca_private_key_pem}" > ~/ca_private_key.pem
