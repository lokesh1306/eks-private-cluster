variable "vpc_id" {
  type        = string
  description = "Init VPC ID of the project"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR of the current project"
}


variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "remote_state" {}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "private_subnet_route_tables" {
  type = list(string)
}
