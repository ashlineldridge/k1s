terraform {
  backend "s3" {
    // All other backend config is specified via make
    workspace_key_prefix = "k1s"
  }
}
