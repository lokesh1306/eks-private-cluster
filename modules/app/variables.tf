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