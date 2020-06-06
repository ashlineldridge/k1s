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

# TODO: get instances from asg names in outputs.sh
