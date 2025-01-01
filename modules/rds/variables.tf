variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "azs" {
  type        = list(string)
  description = "AZs to be used"
}


variable "vpc_id" {
  type        = string
  description = "EKS VPC ID"
}

variable "app_role_name" {
  type        = string
  description = "App role"
}

variable "region" {
  type        = string
  description = "EKS VPC Region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR of the current project"
}

variable "remote_state" {}