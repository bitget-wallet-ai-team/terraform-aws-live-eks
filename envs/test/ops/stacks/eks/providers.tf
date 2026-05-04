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

  # Note: default_tags only apply to newly created resources
  # Existing resources will not be affected

  default_tags {
    tags = {
      Environment = var.environment
      Stack       = "eks"
      ManagedBy   = "terraform"
    }
  }
}

# 使用现有 VPC 资源
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["bk-openclaw-poc-10.15.16.0-20"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["bgw-infra-subnet-*"]
  }
}
