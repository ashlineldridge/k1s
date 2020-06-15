locals {
  encryption_config_template = <<EOF
    kind: EncryptionConfig
    apiVersion: v1
    resources:
    - resources:
      - secrets
      providers:
      - aescbc:
          keys:
          - name: key1
            secret: $${encryption_key}
      - identity: {}
  EOF
}

resource "random_password" "encryption_key" {
  length  = 32
  special = true
}

data "template_file" "encryption_config" {
  template = local.encryption_config_template
  vars = {
    encryption_key = base64encode(random_password.encryption_key.result)
  }
}

