#!/usr/bin/env bash
# shellcheck disable=SC2034

# Provides variables for each of the Terraform outputs

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

terraform_output_json="$(terraform output -json)"
if [[ "${terraform_output_json}" == '{}' ]]; then
  echo >&2 "No Terraform outputs. Are you sure the environment exists?"
  exit 1
fi

# Returns the output value for the provided variable name
terraform_output() {
  local key="${1}"
  local value
  value="$(jq -r ".${key}.value" <<< "${terraform_output_json}")"
  if [[ "${value}" == 'null' ]]; then
    echo >&2 "Terraform output key '${key}' not found"
    exit 1
  fi
  echo "${value}"
}

# Retrieve output values
cluster_name="$(terraform_output cluster_name)"
region="$(terraform_output region)"
bastion_id="$(terraform_output bastion_id)"
