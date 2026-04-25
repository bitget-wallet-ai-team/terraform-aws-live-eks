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

# 临时使用本地值替代 remote state
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["bk-openclaw-poc*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*bgw-infra*"]
  }
}
