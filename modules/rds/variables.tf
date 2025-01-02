variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "azs" {
  type        = list(string)
  description = "AZs to be used"
}


variable "vpc_id" {
  type        = string
  description = "EKS VPC ID"
}

variable "app_role_name" {
  type        = string
  description = "App role"
}

variable "region" {
  type        = string
  description = "EKS VPC Region"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR of the current project"
}

variable "remote_state" {}

variable "rds_cluster_identifier" {
  type        = string
  description = "RDS Cluster Identifier"
}

variable "rds_engine_version" {
  type        = string
  description = "RDS Engine Version"
}

variable "rds_database_name" {
  type        = string
  description = "RDS Database Name"
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS Backup Retention Period"
}

variable "rds_preferred_backup_window" {
  type        = string
  description = "RDS Backup Window"
}

variable "rds_engine" {
  type        = string
  description = "RDS Engine"
}

variable "db_cluster_instance_class" {
  type        = string
  description = "RDS Cluster Instance Class"
}

variable "rds_storage_type" {
  type        = string
  description = "RDS Storage Type"
}

variable "rds_allocated_storage" {
  type        = number
  description = "RDS Allocated Storage"
}

variable "rds_iops" {
  type        = number
  description = "RDS IOPS"
}

variable "master_username" {
  type        = string
  description = "Master Username"
}