#!/usr/bin/env bash

set -eou pipefail

yum update -y \
  https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum-config-manager --enable epel
yum install -y tinyproxy
amazon-linux-extras install docker
usermod -a -G docker ec2-user
systemctl restart amazon-ssm-agent
systemctl start docker
systemctl start tinyproxy
