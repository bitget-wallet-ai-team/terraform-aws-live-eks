# EKS Cluster IAM Role
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])

  policy_arn = each.value
  role       = aws_iam_role.cluster.name
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids             = var.subnet_ids
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policies,
  ]

  tags = var.tags
}

# OIDC Provider
locals {
  oidc_issuer = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_oidc_provider ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}

# Node Group IAM Role
data "aws_iam_policy_document" "node_group_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node_group" {
  name               = "${var.cluster_name}-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_group.name
}

# EKS Managed Node Groups
resource "aws_eks_node_group" "this" {
  for_each = var.eks_managed_node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.subnet_ids

  instance_types = each.value.instance_types
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_group_policies,
  ]

  tags = var.tags
}

# Cluster Addons
resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = lookup(each.value, "most_recent", false) ? null : lookup(each.value, "version", null)

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.this]
}
