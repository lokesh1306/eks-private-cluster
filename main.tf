locals {
  common_tags = merge(var.additional_tags, {
    Project     = var.project_name
    Environment = var.env
  })
}

terraform {
  backend "s3" {
    bucket         = "tf-state-lokesh"
    key            = "prod/infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-lokesh"
  }
}

data "terraform_remote_state" "init" {
  backend = "s3"

  config = {
    bucket         = "tf-state-lokesh"
    key            = "prod/init/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-lokesh"
  }
}

module "network" {
  source               = "./modules/network"
  common_tags          = local.common_tags
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  remote_state         = data.terraform_remote_state.init
}

module "eks" {
  source             = "./modules/eks"
  common_tags        = local.common_tags
  cluster_version    = var.cluster_version
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  region             = var.region
  remote_state       = data.terraform_remote_state.init
  depends_on         = [module.vpcpeer]
}

module "vpcpeer" {
  source                      = "./modules/vpcpeer"
  common_tags                 = local.common_tags
  vpc_id                      = module.network.vpc_id
  vpc_cidr                    = var.vpc_cidr
  remote_state                = data.terraform_remote_state.init
  private_subnet_ids          = module.network.private_subnet_ids
  private_subnet_route_tables = module.network.private_subnet_route_tables
  depends_on                  = [module.network]
}

module "s3" {
  source        = "./modules/s3"
  common_tags   = local.common_tags
  app_role_name = module.app.app_role
  depends_on    = [module.app]
}

module "sqs" {
  source        = "./modules/sqs"
  common_tags   = local.common_tags
  app_role_name = module.app.app_role
  depends_on    = [module.app]
}


module "karpenter" {
  source             = "./modules/karpenter"
  common_tags        = local.common_tags
  cluster_name       = module.eks.cluster_name
  karpenter_name     = var.karpenter_name
  private_subnet_ids = module.network.private_subnet_ids
  region             = var.region
  oidc_provider      = module.eks.oidc_provider
  oidc_provider_arn  = module.eks.oidc_provider_arn
  cluster_endpoint   = module.eks.cluster_endpoint
  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
    helm       = helm
  }
}

module "app" {
  source            = "./modules/app"
  common_tags       = local.common_tags
  oidc_provider     = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn
  providers = {
    kubernetes = kubernetes
    kubectl    = kubectl
    helm       = helm
  }
}