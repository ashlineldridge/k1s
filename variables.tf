variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster"
}

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

variable "pod_cidr_block" {
  type        = string
  description = "CIDR block used internally for the pod network"
}

variable "master_instance_type" {
  type        = string
  description = "EC2 instance type of the master instances"
}

variable "master_instance_count" {
  type        = number
  description = "Total number of master instances"
}

variable "node_instance_type" {
  type        = string
  description = "EC2 instance type of the node instances"
}

variable "node_instance_count" {
  type        = number
  description = "Total number of node instances"
}

variable "bastion_instance_type" {
  type        = string
  description = "EC2 instance type of the bastion instance"
}

