variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "cluster_version" {
  type        = string
  description = "EKS Cluster Name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "region" {
  type        = string
  description = "Region where the resources will be deployed"
}

variable "remote_state" {}

# variable "eks_kms_key" {
#   type        = string
#   description = "Cluster KMS Key"
# }