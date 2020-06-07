#!/usr/bin/env bash

# shellcheck source=scripts/lib/outputs.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/outputs.sh"

ensure_make "list"

usage() {
  cat << EOF
Usage: $(basename "${0}") <roll-type>

Rolls out an update of the masters or nodes by terminating each instance one
by one. A delay will be added at some point to allow the new instance to come
into service. The "roll-type" argument must equal "masters" or "nodes".

EOF
  exit 1
}

(($# != 1)) && usage

roll_type="${1}"
autoscaling_group=master_autoscaling_group

if [[ "${roll_type}" == 'masters' ]]; then
  autoscaling_group="${master_autoscaling_group}"
elif [[ "${roll_type}" == 'nodes' ]]; then
  autoscaling_group="${node_autoscaling_group}"
else
  printf >&2 "Unknown roll-type '%s'\n" "${roll_type}"
  usage
fi

for instance_id in $(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "${autoscaling_group}" \
  --region "${region}" \
  --query 'AutoScalingGroups[].Instances[].InstanceId' \
  --output text); do
  echo >&2 "Terminating ${instance_id}"
  aws ec2 terminate-instances \
    --instance-ids "${instance_id}" \
    --region "${region}" > /dev/null
done
