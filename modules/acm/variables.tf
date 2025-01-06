variable "cf_domain" {
  type        = string
  description = "CF Domain"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "cloudflare_zone_id" {
  type        = string
  description = "CF Zone ID"
}