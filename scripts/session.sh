#!/usr/bin/env bash

# shellcheck source=scripts/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

usage() {
  cat << EOF
Usage: $(basename "${0}") <instance-id> <region>

Establishes an AWS Session Manager session with the specified instance.

EOF
  exit 1
}

(($# != 2)) && usage

instance_id="${1}"
region="${2}"

aws ssm start-session --target "${instance_id}" --region "${region}"
