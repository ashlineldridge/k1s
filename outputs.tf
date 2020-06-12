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

output "master_instance_ids" {
  description = "IDs of the Kubernetes master instances"
  value       = aws_instance.master[*].id
}

output "master_private_ips" {
  description = "Private IP addresses of the Kubernetes master instances"
  value       = aws_instance.master[*].private_ip
}

output "node_instance_ids" {
  description = "IDs of the Kubernetes node instances"
  value       = aws_instance.node[*].id
}

output "node_private_ips" {
  description = "Private IP addresses of the Kubernetes node instances"
  value       = aws_instance.node[*].private_ip
}

output "bastion_id" {
  description = "ID of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion EC2 instance"
  value       = aws_instance.bastion.private_ip
}

output "api_load_balancer_dns_name" {
  description = "Internal DNS name for the Kubernetes API load balancer"
  value       = aws_lb.kube_api.dns_name
}

output "kube_api_nlb_ips" {
  description = "Public IP addresses for the Kubernetes API NLB"
  value       = data.dns_a_record_set.kube_api_nlb.addrs
}

