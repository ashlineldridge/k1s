locals {
  // Name of the Kubernetes cluster
  cluster_name = "k1s"

  // Cluster identifier that is unique across regions
  cluster_id = "${local.cluster_name}-${local.region_codes[var.region]}"

  // Map of region identifier to abbreviated code - useful for
  // length restricted identifiers such as name_prefix
  region_codes = {
    us-east-1      = "use1"
    us-east-2      = "use2"
    us-west-1      = "usw1"
    us-west-2      = "usw2"
    ap-southeast-1 = "apse1"
    ap-southeast-2 = "apse2"
  }

  // Common tags to be applied to all taggable resources
  common_tags = {
    cluster-name   = local.cluster_name
    cluster-region = var.region
  }

  // Common autoscaling group tags which need to be specified in a different format
  common_asg_tags = [
    for k, v in local.common_tags : {
      key                 = k
      value               = v
      propagate_at_launch = true
    }
  ]
}
