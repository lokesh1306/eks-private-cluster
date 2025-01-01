variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "cluster_version" {
  type        = string
  description = "EKS Cluster Version"
}

variable "vpc_id" {
  type        = string
  description = "EKS VPC ID"
}

variable "private_subnet_ids" {
  description = "EKS Private Subnet IDs"
  type        = list(string)
}

variable "region" {
  type        = string
  description = "EKS VPC Region"
}

variable "remote_state" {}