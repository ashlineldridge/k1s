terraform {
  backend "s3" {
    workspace_key_prefix = "k1s"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 2.1"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "~> 2.2"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 1.4"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 2.2"
    }
  }

  required_version = ">= 0.13"
}

provider "aws" {
  region = var.region
}
