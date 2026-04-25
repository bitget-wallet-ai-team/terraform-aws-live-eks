# EKS Cluster IAM Role - 支持现有角色
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

# 查找现有 cluster role
data "aws_iam_role" "existing_cluster" {
  count = var.create_cluster_role ? 0 : 1
  name  = var.cluster_role_name
}

resource "aws_iam_role" "cluster" {
  count = var.create_cluster_role ? 1 : 0

  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json

  tags = var.tags
}

locals {
  cluster_role_arn = var.create_cluster_role ? aws_iam_role.cluster[0].arn : data.aws_iam_role.existing_cluster[0].arn
  cluster_role_name = var.create_cluster_role ? aws_iam_role.cluster[0].name : data.aws_iam_role.existing_cluster[0].name
}

resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = var.create_cluster_role ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ]) : toset([])

  policy_arn = each.value
  role       = local.cluster_role_name
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = local.cluster_role_arn

  vpc_config {
    subnet_ids             = var.subnet_ids
    endpoint_public_access = var.endpoint_public_access
    public_access_cidrs    = var.public_access_cidrs
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = var.tags

  lifecycle {
    ignore_changes = all
  }
}

# OIDC Provider
data "tls_certificate" "eks" {
  count = var.enable_oidc_provider ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_oidc_provider ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.eks[0].certificates[*].sha1_fingerprint
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = var.tags
}

# Node Group IAM Role - 支持现有角色
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

# 查找现有 node role
data "aws_iam_role" "existing_node" {
  count = var.create_node_role ? 0 : 1
  name  = var.node_role_name
}

resource "aws_iam_role" "node_group" {
  count = var.create_node_role ? 1 : 0

  name               = "${var.cluster_name}-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.node_group_assume_role.json

  tags = var.tags
}

locals {
  node_role_arn = var.create_node_role ? aws_iam_role.node_group[0].arn : data.aws_iam_role.existing_node[0].arn
  node_role_name = var.create_node_role ? aws_iam_role.node_group[0].name : data.aws_iam_role.existing_node[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_policies" {
  for_each = var.create_node_role ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]) : toset([])

  policy_arn = each.value
  role       = local.node_role_name
}

# EKS Managed Node Groups
resource "aws_eks_node_group" "this" {
  for_each = var.eks_managed_node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = each.value.name
  node_role_arn   = local.node_role_arn
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
