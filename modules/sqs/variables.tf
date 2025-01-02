variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "app_role_name" {
  type        = string
  description = "App role"
}

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

variable "region" {
  type        = string
  description = "Region"
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  type        = string
  description = "Init VPC ID of the project"
}
