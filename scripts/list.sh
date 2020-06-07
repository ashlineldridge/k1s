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

no_color='\033[0m'
banner_color='\033[32;01m'
underline_on='\033[4m'
underline_off='\033[24m'

# Prints a title banner
print_banner() {
  printf "%b\n%s\n\n%b" "${banner_color}" "${1}" "${no_color}"
}

# Prints launch template information
print_launch_template_info() {
  launch_template_id="${1}"
  IFS=$'\t' read -r template_name latest_version <<< "$(aws ec2 describe-launch-templates \
    --launch-template-id "${launch_template_id}" \
    --region "${region}" \
    | jq -er '.LaunchTemplates[] | [.LaunchTemplateName, .LatestVersionNumber] | @tsv')"
  printf '%b%-21s %-15s%b\n' "${underline_on}" 'Launch Template Name' 'Latest Version' "${underline_off}"
  printf '%-21s %-15s\n\n' "${template_name}" "${latest_version}"
}

# Prints EC2 instance information
print_instance_info() {
  local autoscaling_group="${1}"
  printf '%b%-20s %-16s %-14s %-17s%b\n' \
    "${underline_on}" \
    'Instance ID' 'Lifecycle State' 'Health Status' 'Template Version' \
    "${underline_off}"

  aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "${autoscaling_group}" \
    --region "${region}" \
    | jq -er '.AutoScalingGroups[].Instances[]
    | [.InstanceId, .LifecycleState, .HealthStatus, .LaunchTemplate.Version] | @tsv' \
    | while IFS=$'\t' read -r id state status version; do
      printf '%-20s %-16s %-14s %-17s\n' "${id}" "${state}" "${status}" "${version}"
    done
}

print_banner 'Kubernetes Masters'
print_launch_template_info "${master_launch_template_id}"
print_instance_info "${master_autoscaling_group}"

print_banner 'Kubernetes Nodes'
print_launch_template_info "${node_launch_template_id}"
print_instance_info "${node_autoscaling_group}"

print_banner 'Bastion'
printf '%b%-20s%b\n' "${underline_on}" 'Instance ID' "${underline_off}"
printf "%s\n" "${bastion_id}"
