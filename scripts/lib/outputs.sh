#!/usr/bin/env bash
# shellcheck disable=SC2034

# Provides variables for each of the Terraform outputs

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

__tf_output_json="$(terraform output -json)"
if [[ "${__tf_output_json}" == '{}' ]]; then
  echo >&2 "No Terraform outputs. Are you sure the environment exists?"
  exit 1
fi

# Returns the output value for the provided variable name
__tf_output() {
  local key="${1}"
  local value
  value="$(jq -r ".${key}.value" <<< "${__tf_output_json}")"
  if [[ "${value}" == 'null' ]]; then
    echo >&2 "Terraform output key '${key}' not found"
    exit 1
  fi
  echo "${value}"
}

# Retrieve output values
cluster_name="$(__tf_output cluster_name)"
region="$(__tf_output region)"
master_autoscaling_group="$(__tf_output master_autoscaling_group)"
node_autoscaling_group="$(__tf_output node_autoscaling_group)"
bastion_id="$(__tf_output bastion_id)"
