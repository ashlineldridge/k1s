resource "aws_autoscaling_group" "master" {
  name                = "${local.cluster_id}-master"
  vpc_zone_identifier = module.vpc.private_subnets
  desired_capacity    = 3
  max_size            = 3
  min_size            = 3
  force_delete        = true

  launch_template {
    id      = aws_launch_template.master.id
    version = aws_launch_template.master.latest_version
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

  iam_instance_profile {
    arn = aws_iam_instance_profile.master.arn
  }

  user_data = filebase64("${path.module}/scripts/launch/master.sh")
}

resource "aws_iam_role" "master" {
  name                  = "${local.cluster_id}-master"
  assume_role_policy    = data.aws_iam_policy_document.ec2_assume.json
  force_detach_policies = true
  tags                  = local.common_tags
}

resource "aws_iam_role_policy" "master_session_manager" {
  policy = data.aws_iam_policy_document.session_manager.json
  role   = aws_iam_role.master.name
}

resource "aws_iam_instance_profile" "master" {
  role = aws_iam_role.master.name
}


