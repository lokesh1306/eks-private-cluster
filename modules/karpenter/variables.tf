variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "karpenter_name" {
  type        = string
  description = "Karpenter Name Used"
}

variable "region" {
  type        = string
  description = "AWS Region"
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "oidc_provider" {
  type        = string
  description = "OIDC Provider"
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC Provider ARN"
}

variable "cluster_endpoint" {
  type        = string
  description = "Cluster Endpoint"
}
