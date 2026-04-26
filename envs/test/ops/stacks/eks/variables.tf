variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "test"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "test-ops"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "node_instance_types" {
  description = "Node group instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Node group desired size"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Node group min size"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Node group max size"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
