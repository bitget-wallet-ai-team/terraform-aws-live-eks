variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS"
  type        = list(string)
}

variable "eks_managed_node_groups" {
  description = "EKS managed node groups configuration"
  type        = any
  default     = {}
}

variable "enable_oidc_provider" {
  description = "Enable OIDC provider"
  type        = bool
  default     = true
}

variable "cluster_addons" {
  description = "Cluster addons configuration"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
