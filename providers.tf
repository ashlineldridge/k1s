provider "aws" {
  region  = var.region
  version = "~> 2.66"
}

provider "tls" {
  version = "~> 2.1"
}

provider "dns" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.4"
}

provider "random" {
  version = "~> 2.2"
}
