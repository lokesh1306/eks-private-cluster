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

variable "mysql_sg_id" {
  description = "MySQL SG ID"
  type        = string
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR of the current project"
}

variable "region" {
  type        = string
  description = "EKS VPC Region"
}

variable "mysql_cluster_id" {
  description = "MySQL Cluster ID"
  type        = string
}

variable "cluster_resource_id" {
  description = "MySQL Cluster ID"
  type        = string
}

variable "mysql_cluster_endpoint" {
  description = "MySQL Cluster Endpoint"
  type        = string
}

variable "mysql_cluster_database_name" {
  description = "MySQL Cluster DB"
  type        = string
}

variable "app_mysql_user" {
  type        = string
  description = "RDS App Username"
}

variable "cluster_name_fargate" {
  type        = string
  description = "Karpenter cluster name"
}

variable "aws_acm_certificate_arn" {
  type        = string
  description = "ACM ARN"
}