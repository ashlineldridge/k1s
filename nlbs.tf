resource "aws_lb" "kube_api_public" {
  name                             = "${local.cluster_id}-kube-api-public"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = module.vpc.public_subnets
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  tags                             = local.common_tags

  // So that the NLB doesn't steal the fixed IPs of the instances
  depends_on = [aws_instance.bastion, aws_instance.master, aws_instance.node]
}

resource "aws_lb_listener" "kube_api_public" {
  load_balancer_arn = aws_lb.kube_api_public.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_api_public.arn
  }
}

resource "aws_lb_target_group" "kube_api_public" {
  name        = "${local.cluster_id}-kube-api-public"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags

  health_check {
    interval = 10
    port     = 6443
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "kube_api_public" {
  count = var.master_instance_count

  target_group_arn = aws_lb_target_group.kube_api_public.arn
  target_id        = aws_instance.master[count.index].id
  port             = 443
}

resource "aws_lb" "kube_api_private" {
  name                             = "${local.cluster_id}-kube-api-private"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = module.vpc.private_subnets
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  tags                             = local.common_tags

  // So that the NLB doesn't steal the fixed IPs of the instances
  depends_on = [aws_instance.bastion, aws_instance.master, aws_instance.node]
}

resource "aws_lb_listener" "kube_api_private" {
  load_balancer_arn = aws_lb.kube_api_private.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_api_private.arn
  }
}

resource "aws_lb_target_group" "kube_api_private" {
  name        = "${local.cluster_id}-kube-api-private"
  port        = 6443
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id
  tags        = local.common_tags

  health_check {
    interval = 10
    port     = 6443
    protocol = "TCP"
  }
}

resource "aws_lb_target_group_attachment" "kube_api_private" {
  count = var.master_instance_count

  target_group_arn = aws_lb_target_group.kube_api_private.arn
  target_id        = aws_instance.master[count.index].id
  port             = 443
}
