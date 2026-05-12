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
  description = "Existing EKS cluster name to deploy into"
  type        = string
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "golang-app"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "replica_count" {
  description = "Number of pod replicas"
  type        = number
  default     = 3
}

variable "image_repository" {
  description = "Container image repository"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
}

variable "container_port" {
  description = "Container listening port"
  type        = number
  default     = 8082
}

variable "service_port" {
  description = "Service exposed port"
  type        = number
  default     = 80
}

variable "cpu" {
  description = "Per-pod CPU (requests=limits)"
  type        = string
  default     = "1000m"
}

variable "memory" {
  description = "Per-pod memory (requests=limits)"
  type        = string
  default     = "1Gi"
}
