locals {
  name = "${var.environment}-ops-eks"
}

module "eks" {
  source = "../../../../../modules/eks/cluster"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids

  # 使用现有 IAM 角色
  create_cluster_role = false
  cluster_role_name   = "AmazonEKSAutoClusterRole"
  create_node_role    = false
  node_role_name      = "bgw-eks-node-role-test"

  # 托管节点组 - 匹配现网配置
  eks_managed_node_groups = {
    bgw_infra_ec2_group = {
      name           = "bgw-infra-ec2-group"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      capacity_type = "ON_DEMAND"
    }
  }

  # 启用 OIDC provider
  enable_oidc_provider = true

  # Cluster addons - 匹配现网配置
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    metrics-server = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  tags = merge(var.tags, {
    Name = local.name
  })
}
