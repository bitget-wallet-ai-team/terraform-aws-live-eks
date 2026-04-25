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

variable "create_cluster_role" {
  description = "Create new cluster IAM role or use existing"
  type        = bool
  default     = true
}

variable "cluster_role_name" {
  description = "Name of existing cluster IAM role"
  type        = string
  default     = ""
}

variable "create_node_role" {
  description = "Create new node IAM role or use existing"
  type        = bool
  default     = true
}

variable "node_role_name" {
  description = "Name of existing node IAM role"
  type        = string
  default     = ""
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks for public access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
