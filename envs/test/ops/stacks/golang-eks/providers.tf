terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Stack       = "golang-eks"
      ManagedBy   = "terraform"
      Cluster     = var.cluster_name
    }
  }
}

# 复用现有 VPC
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["bk-openclaw-poc-10.15.16.0-20"]
  }
}

# 复用现有私有子网 (EKS 节点所用)
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
