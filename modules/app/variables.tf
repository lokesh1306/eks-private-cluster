variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "oidc_provider_arn" {
  type        = string
  description = "OIDC Provider ARN"
}

variable "oidc_provider" {
  type        = string
  description = "OIDC Provider"
}