provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.18.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0, < 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
  }
}

data "aws_eks_cluster_auth" "default" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster" "default" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_secretsmanager_secret" "cloudflare" {
  name = "prod/cloudflare"
}

data "aws_secretsmanager_secret_version" "cloudflare" {
  secret_id = data.aws_secretsmanager_secret.cloudflare.id
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.default.endpoint
  token                  = data.aws_eks_cluster_auth.default.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  load_config_file       = false
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.default.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.default.token
  }
}

provider "cloudflare" {
  api_key = jsondecode(data.aws_secretsmanager_secret_version.cloudflare.secret_string)["key"]
  email   = var.cf_email
}