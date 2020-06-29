//
// Kubernetes resources (required by masters)
//

resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

data "template_file" "encryption_config" {
  template = file("${path.module}/cloud-init/master/encryption.yaml")
  vars = {
    encryption_key = base64encode(random_password.encryption_key.result)
  }
}
