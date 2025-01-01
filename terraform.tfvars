# General vars
region       = "us-east-1"
project_name = "eks"
env          = "prod"

# Network vars
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]

# EKS module vars
cluster_name    = "eks"
cluster_version = "1.30"

# SQS module vars
visibility_timeout_seconds = 30
message_retention_seconds  = 86400
delay_seconds              = 0
fifo_queue                 = false

# Karpenter module
karpenter_name = "karpenter"

# App module vars
github_owner  = "lokesh1306"
repo_name     = "helm"
release_name  = "eks-app"
chart_name    = "eks-app"
chart_version = null