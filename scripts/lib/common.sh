#!/usr/bin/env bash
# shellcheck disable=SC2034

# Provides common variables and functionality required by other scripts.

set -eou pipefail

# Export SHELLOPTS for subshells
export SHELLOPTS

# Ensure that the CWD of all scripts is the repo root
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${root_dir}"

# Ensure build directory exists
build_dir=target
mkdir -p "${build_dir}"

# Ensure we were invoked via the Makefile
ensure_make() {
  local make_target="${1}"
  if [[ -z "${MAKE:-}" ]]; then
    echo >&2 "Error: Cannot run script directly."
    echo >&2 "Invoke via 'make ${make_target}' to ensure correct initialisation."
    exit 1
  fi
}
