variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "app_role_name" {
  type        = string
  description = "App role"
}