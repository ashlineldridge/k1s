vpc_cidr_block             = "10.0.0.0/20"
public_subnet_cidr_blocks  = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]
private_subnet_cidr_blocks = ["10.0.4.0/22", "10.0.8.0/22", "10.0.12.0/22"]
master_instance_type       = "t3.medium"
master_instance_count      = 3
node_instance_type         = "t3.medium"
node_instance_count        = 3
bastion_instance_type      = "t3.micro"
