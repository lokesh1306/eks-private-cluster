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

// SSM Module
variable "bastion_ami_id" {
  type        = string
  description = "AMI ID of the Bastion Host"
}

variable "bastion_instance_type" {
  type        = string
  description = "Bastion Host Instance Type"
}

// Karpenter Module
variable "karpenter_name" {
  type        = string
  description = "Karpenter Name Used"
}