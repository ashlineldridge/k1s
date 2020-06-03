resource "aws_autoscaling_group" "control_plane" {
  availability_zones = data.aws_availability_zones.all.names
  desired_capacity   = 3
  max_size           = 3
  min_size           = 3

  launch_template {
    id      = aws_launch_template.control_plane.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "control_plane" {
  name          = "${local.cluster_id}-control-plane"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
}

