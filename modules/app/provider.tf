terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.18.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0.0"
    }
  }
}

provider "mysql" {
  endpoint = var.mysql_cluster_endpoint
  username = local.mysql_credentials["username"]
  password = local.mysql_credentials["password"]
}