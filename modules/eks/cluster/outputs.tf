output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = var.enable_oidc_provider ? aws_iam_openid_connect_provider.this[0].arn : null
}

output "cluster_iam_role_arn" {
  description = "Cluster IAM role ARN"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "Node group IAM role ARN"
  value       = aws_iam_role.node_group.arn
}
