terraform {
  backend "s3" {
    // All other backend config is specified via make
    workspace_key_prefix = "k1s"
  }
}

provider "aws" {
  region  = var.region
  version = "~> 2.0"
}

data "aws_availability_zones" "all" {}
