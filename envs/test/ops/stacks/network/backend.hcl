terraform {
  backend "s3" {
    key = "test/ops/network/terraform.tfstate"
  }
}
