resource "aws_lb" "kube_api" {
  name                             = "${local.cluster_id}-api"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = module.vpc.public_subnets
  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true
  tags                             = local.common_tags
}

resource "aws_lb_listener" "kube_api" {
  load_balancer_arn = aws_lb.kube_api.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_api.arn
  }
}

resource "aws_lb_target_group" "kube_api" {
  name     = "${local.cluster_id}-api"
  port     = 443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
  tags     = local.common_tags
}
