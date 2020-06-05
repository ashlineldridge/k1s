#!/usr/bin/env bash
# shellcheck disable=SC2034

# Provides common variables and functionality required by other scripts.

set -eou pipefail

# Export SHELLOPTS for subshells
export SHELLOPTS

# Check that Tinyproxy is installed
if ! command -v tinyproxy > /dev/null 2>&1; then
  echo 'Error: Tinyproxy is not installed'
  exit 1
fi

# Ensure that the CWD of all scripts is the repo root
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${root_dir}"

# Ensure build directory exists
build_dir=target
mkdir -p "${build_dir}"

#
# Cleans up any SSH and Tinyproxy background processes.
#
proxy_cleanup() {
  echo >&2 "Cleaning up background proxy processes"
  pkill -f '^ssh.*AWS-StartSSHSession' || true
  pkill tinyproxy || true
}

#
# Returns the instance ID of the bastion host.
#
bastion_id() {
  local cluster_name="${1}"
  local region="${2}"
  aws ssm get-parameter \
    --name "/gantry/${cluster_name}/bastion-id" \
    --region "${region}" \
    --query Parameter.Value \
    --output text
}

#
# Returns an unused local port.
#
local_port() {
  python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()'
}

#
# Installs a temporary SSH key onto an EC2 instance using EC2 Instance Connect.
# This function  returns the path to the SSH key on the local filesystem.
#
install_ssh_key() {
  local instance_id="${1}"
  local region="${2}"
  local key="${build_dir}/${instance_id}-ssh-key"

  # Regenerate the SSH key
  rm -f "${key}" "${key}.pub"
  ssh-keygen -t rsa -f "${key}" -N "" > /dev/null

  # Get the AZ that the bastion is deployed into
  local instance_az
  instance_az=$(aws ec2 describe-instances \
    --instance-id "${instance_id}" \
    --region "${region}" \
    --query "Reservations[0].Instances[0].Placement.AvailabilityZone" \
    --output text)

  # Install the SSH key onto the bastion host
  aws ec2-instance-connect send-ssh-public-key \
    --instance-id "${instance_id}" \
    --availability-zone "${instance_az}" \
    --instance-os-user ec2-user \
    --region "${region}" \
    --ssh-public-key "file://${key}.pub" > /dev/null 2>&1

  echo "${key}"
}

#
# Starts a background SOCKS proxy session with the bastion host by
# establishing an SSH connection of an AWS Session Manager session.
#
start_socks_proxy() {
  local cluster_name="${1}"
  local region="${2}"
  local port="${3}"

  local bastion_id
  bastion_id="$(bastion_id "${cluster_name}" "${region}")"

  echo >&2 "Starting SOCKS proxy on port ${port}"

  ssh -CN \
    -D "127.0.0.1:${port}" \
    -o LogLevel=error \
    -o StrictHostKeyChecking=no \
    -o IdentitiesOnly=yes \
    -o ProxyCommand="bash -c 'aws ssm start-session \\
      --target %h \\
      --document-name AWS-StartSSHSession \\
      --parameters portNumber=%p \\
      --region ${region}'" \
    -i "$(install_ssh_key "${bastion_id}" "${region}")" \
    "ec2-user@${bastion_id}" &
}

#
# Starts a background HTTP proxy (Tinyproxy) that listens on the specified local
# port and forwards to the specified SOCKS remote port (on this host).
#
start_http_proxy() {
  local port="${1}"
  local remote_port="${2}"
  local conf_file="${build_dir}/proxy-${port}.conf"

  # Setup Tinyproxy to forward traffic to the SOCKS proxy
  cat << EOF > "${conf_file}"
Port ${port}
Timeout 600
LogLevel Error
Upstream socks5 127.0.0.1:${remote_port}
MaxClients 100
MinSpareServers 5
MaxSpareServers 25
StartServers 10
MaxRequestsPerChild 0
ViaProxyName "tinyproxy"
EOF

  echo >&2 "Starting HTTP proxy on ${port} to forward to SOCKS proxy"
  tinyproxy -c "${conf_file}" 2> /dev/null
}

#
# Waits for the proxy chain to settle. Note: if you see errors along the lines of
# "Unable to connect to upstream proxy" then try increasing the wait period.
#
# shellcheck disable=SC2120
proxy_wait() {
  settle_time="${1:-5s}"
  printf >&2 "Proxy chain started. Waiting %s for connection to settle...\n" "${settle_time}"
  sleep "${settle_time}"
}

#
# Starts a background HTTP proxy (Tinyproxy) that forwards to a SOCKS proxied
# connection to the bastion host for the specified cluster. This function returns
# the port number of HTTP proxy.
#
start_proxy_chain() {
  cluster_name="${1}"
  region="${2}"
  http_proxy_port="${3:-}"

  # Assign port numbers
  socks_proxy_port="$(local_port)"
  if [[ "${http_proxy_port}" == '' || "${http_proxy_port}" == '0' ]]; then
    http_proxy_port="$(local_port)"
  fi

  # Start the proxy chain
  start_socks_proxy "${cluster_name}" "${region}" "${socks_proxy_port}"
  start_http_proxy "${http_proxy_port}" "${socks_proxy_port}"
  proxy_wait

  echo "${http_proxy_port}"
}
