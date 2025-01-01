// General variables
variable "region" {
  type        = string
  description = "Region where the resources will be deployed"
}

variable "env" {
  type        = string
  description = "Environment where resources will be deployed"
}

variable "project_name" {
  type        = string
  description = "Project Name"
}

variable "additional_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}

// Network module variables
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR Block"
  validation {
    condition     = contains(["10.0.0.0/16", "192.168.0.0/16", "172.31.0.0/16"], var.vpc_cidr)
    error_message = "Please enter a valid CIDR. Allowed values are 10.0.0.0/16, 192.168.0.0/16 and 172.31.0.0/16"
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnets for VPC"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnets for VPC"
}

variable "azs" {
  type        = list(string)
  description = "AZs to be used"
}

// EKS module variables
variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "cluster_version" {
  type        = string
  description = "EKS Cluster Version"
}

// SQS Module
variable "visibility_timeout_seconds" {
  type        = number
  description = "SQS queue visibility timeout"
}

variable "message_retention_seconds" {
  type        = number
  description = "SQS queue message retention timeout"
}

variable "delay_seconds" {
  type        = number
  description = "SQS queue delay seconds"
}

variable "fifo_queue" {
  type        = bool
  description = "SQS queue fifo or no"
}

// Karpenter Module
variable "karpenter_name" {
  type        = string
  description = "Karpenter Name Used"
}

// App module
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "release_name" {
  description = "Name of the Helm release"
  type        = string
}

variable "chart_name" {
  description = "Name of the Helm chart"
  type        = string
}

variable "chart_version" {
  description = "Version of the Helm chart (leave empty for latest)"
  type        = string
}