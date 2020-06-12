provider "aws" {
  region  = var.region
  version = "2.65.0"
}

provider "tls" {
  version = "2.1.1"
}

provider "dns" {
  version = "2.2.0"
}
