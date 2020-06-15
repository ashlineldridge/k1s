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
kube_controller_manager_config="${kube_controller_manager_config}"
kube_scheduler_config="${kube_scheduler_config}"
admin_config="${admin_config}"
encryption_config="${encryption_config}"

echo "$${domain_name}" > ~/hello.txt
echo "$${ca_cert_pem}" > ~/ca_cert.pem
echo "$${ca_private_key_pem}" > ~/ca_private_key.pem
echo "$${kube_controller_manager_config}" > ~/kube_controller_manager.config
echo "$${kube_scheduler_config}" > ~/kube_scheduler.config
echo "$${admin_config}" > ~/admin.config
echo "$${encryption_config}" > ~/encryption_config.yaml
