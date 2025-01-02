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
  source                     = "./modules/sqs"
  common_tags                = local.common_tags
  app_role_name              = module.app.app_role
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  fifo_queue                 = var.fifo_queue
  depends_on                 = [module.app]
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
  depends_on = [module.eks]
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
  github_owner                = var.github_owner
  repo_name                   = var.repo_name
  release_name                = var.release_name
  chart_name                  = var.chart_name
  chart_version               = var.chart_version
  mysql_sg_id                 = module.rds.mysql_sg_id
  vpc_cidr                    = var.vpc_cidr
  region                      = var.region
  mysql_cluster_id            = module.rds.mysql_cluster_id
  cluster_resource_id = module.rds.cluster_resource_id
  mysql_cluster_endpoint      = module.rds.mysql_cluster_endpoint
  mysql_cluster_database_name = module.rds.mysql_cluster_database_name
  app_mysql_user              = var.app_mysql_user
  cluster_name_fargate        = module.karpenter.cluster_name_fargate
  delete_fargate_profile_dependency = module.karpenter.delete_fargate_profile_complete
}

module "rds" {
  source                      = "./modules/rds"
  common_tags                 = local.common_tags
  private_subnet_ids          = module.network.private_subnet_ids
  azs                         = var.azs
  vpc_id                      = module.network.vpc_id
  app_role_name               = module.app.app_role
  region                      = var.region
  vpc_cidr                    = var.vpc_cidr
  remote_state                = data.terraform_remote_state.init
  rds_cluster_identifier      = var.rds_cluster_identifier
  rds_engine                  = var.rds_engine
  rds_database_name           = var.rds_database_name
  rds_engine_version          = var.rds_engine_version
  master_username             = var.master_username
  rds_backup_retention_period = var.rds_backup_retention_period
  rds_preferred_backup_window = var.rds_preferred_backup_window
  db_cluster_instance_class   = var.db_cluster_instance_class
  rds_storage_type            = var.rds_storage_type
  rds_allocated_storage       = var.rds_allocated_storage
  rds_iops                    = var.rds_iops
  depends_on                  = [module.vpcpeer]
}