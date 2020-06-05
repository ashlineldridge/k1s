#!/usr/bin/env bash

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat << EOF
Usage: $(basename "${0}") <cluster-name> <region>

Lists the EC2 instances in the project according to their type (i.e.,
bastion, master, or node) for the specified cluster.

EOF
  exit 1
}

(($# != 2)) && usage

cluster_name="${1}"
region="${2}"

master_asg_name="${cluster_name}-${region}-master"
node_asg_name="${cluster_name}-${region}-node"
bastion_name="${cluster_name}-${region}-bastion"

printf "\nMaster instances:\n"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${master_asg_name}" \
  --region "${region}" \
  --query 'AutoScalingGroups[].Instances[].InstanceId' \
  --output text

printf "\nNode instances:\n"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${node_asg_name}" \
  --region "${region}" \
  --query 'AutoScalingGroups[].Instances[].InstanceId' \
  --output text

printf "\nBastion instance:\n"
aws ec2 describe-instances \
  --region "${region}" \
  --filters "Name=tag:Name,Values=${bastion_name}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].InstanceId[]' \
  --output text
