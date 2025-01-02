variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "app_role_name" {
  type        = string
  description = "App role"
}

variable "vpc_id" {
  type        = string
  description = "Init VPC ID of the project"
}

variable "region" {
  type        = string
  description = "Region"
}

variable "private_subnet_route_tables" {
  type = list(string)
}
