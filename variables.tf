variable "region" {
  type        = string
  description = "AWS region to provision resources in"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the cluster VPC"
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks for the public subnets"
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks for the private subnets"
}

variable "control_plane_instance_type" {
  type        = string
  description = "EC2 instance type of the control plane instances"
}

variable "node_group_instance_type" {
  type        = string
  description = "EC2 instance type of the node group instances"
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type of the bastion instance"
}

