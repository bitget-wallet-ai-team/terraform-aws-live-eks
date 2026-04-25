terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Stack       = "eks"
      ManagedBy   = "terraform"
    }
  }
}

# 读取 network stack 输出
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
    key    = "test/ops/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "aws_caller_identity" "current" {}
