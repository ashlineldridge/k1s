resource "aws_autoscaling_group" "master" {
  vpc_zone_identifier = module.vpc.private_subnets
  desired_capacity    = 3
  max_size            = 3
  min_size            = 3
  force_delete        = true

  launch_template {
    id      = aws_launch_template.master.id
    version = "$Latest"
  }

  tags = concat(local.common_asg_tags, [{
    key                 = "Name"
    value               = "${local.cluster_id}-master"
    propagate_at_launch = true
  }])
}

resource "aws_launch_template" "master" {
  name          = "${local.cluster_id}-master"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.master_instance_type
  tags          = local.common_tags
}

