locals {
  name = var.cluster_name
}

module "eks" {
  source = "../../../../../modules/eks/cluster"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids

  # 复用现有 IAM 角色 (SCP 限制不允许创建新 IAM role)
  create_cluster_role = false
  cluster_role_name   = "AmazonEKSAutoClusterRole"
  create_node_role    = false
  node_role_name      = "bgw-eks-node-role-test"

  # 托管节点组: 2 × t3.medium 满足 3 × (1C/1G) pod + 系统开销
  eks_managed_node_groups = {
    golang_workers = {
      name           = "${var.cluster_name}-workers"
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      capacity_type  = "ON_DEMAND"
    }
  }

  enable_oidc_provider = true

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

# EKS Access Entries — Jenkins + SSO role 授 cluster-admin
resource "aws_eks_access_entry" "admin" {
  for_each = var.cluster_admin_role_arns

  cluster_name  = module.eks.cluster_name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = var.cluster_admin_role_arns

  cluster_name  = module.eks.cluster_name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
