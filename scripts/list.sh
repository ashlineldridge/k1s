#!/usr/bin/env bash

# shellcheck source=scripts/lib/outputs.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/outputs.sh"

ensure_make "list"

usage() {
  cat << EOF
Usage: $(basename "${0}")

Lists the EC2 instances in the project according to their type (i.e.,
bastion, master, or node) for the current cluster.

EOF
  exit 1
}

(($# != 0)) && usage

printf "\nMaster instances:\n"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${master_autoscaling_group}" \
  --region "${region}" \
  --query 'AutoScalingGroups[].Instances[].InstanceId' \
  --output text

printf "\nNode instances:\n"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${node_autoscaling_group}" \
  --region "${region}" \
  --query 'AutoScalingGroups[].Instances[].InstanceId' \
  --output text

printf "\nBastion instance:\n${bastion_id}\n"
