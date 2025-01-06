variable "cf_email" {
  type        = string
  description = "CF Email"
}

variable "cf_domain" {
  type        = string
  description = "CF Domain"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "delete_fargate_profile_dependency" {
  type = string
}