resource "aws_autoscaling_group" "node_group" {
  availability_zones = data.aws_availability_zones.all.names
  desired_capacity   = 3
  max_size           = 3
  min_size           = 3

  launch_template {
    id      = aws_launch_template.node_group.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "node_group" {
  name          = "${local.cluster_id}-node-group"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
}
