locals {

  name_prefix = "app-${local.env}"

  instance_type = var.instance_type[local.env]

  tags = {
    Environment = local.env
    Terraform   = "true"
  }
}