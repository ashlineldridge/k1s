// Reads the DNS records of the Kube API NLB
data "dns_a_record_set" "kube_api_public" {
  host = aws_lb.kube_api_public.dns_name
}

resource "aws_route53_zone" "private" {
  name          = local.private_zone_name
  comment       = "Private zone for cluster ${local.cluster_id}"
  force_destroy = true

  vpc {
    vpc_id = module.vpc.vpc_id
  }

  tags = local.common_tags
}

resource "aws_route53_record" "kube_api_private_nlb" {
  zone_id = aws_route53_zone.private.zone_id
  name    = local.kube_api_private_domain
  type    = "A"

  alias {
    name                   = aws_lb.kube_api_private.dns_name
    zone_id                = aws_lb.kube_api_private.zone_id
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "public" {
  name = var.public_zone_name
}

resource "aws_route53_record" "kube_api_public_nlb" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.kube_api_public_domain
  type    = "A"

  alias {
    name                   = aws_lb.kube_api_public.dns_name
    zone_id                = aws_lb.kube_api_public.zone_id
    evaluate_target_health = false
  }
}
