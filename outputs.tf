output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.cluster_name
}

output "region" {
  description = "AWS region that resources are provisioned in"
  value       = var.region
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "master_autoscaling_group" {
  description = "Name of the autoscaling group for the Kubernetes masters"
  value       = aws_autoscaling_group.master.name
}

output "master_launch_template_id" {
  description = "ID of the launch template for the Kubernetes masters"
  value       = aws_launch_template.master.id
}

output "node_autoscaling_group" {
  description = "Name of the autoscaling group for the Kubernetes nodes"
  value       = aws_autoscaling_group.node.name
}

output "node_launch_template_id" {
  description = "ID of the launch template for the Kubernetes nodes"
  value       = aws_launch_template.node.id
}

output "bastion_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}
