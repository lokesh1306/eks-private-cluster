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

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "remote_state" {}
