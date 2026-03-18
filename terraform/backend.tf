terraform {
  backend "s3" {
    bucket         = "app-96321"
    key            = "omnicloud/terraform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}