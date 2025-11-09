terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "prod"
      Project     = "aws-eks-ent-multi-az-cluster"
      ManagedBy   = "terraform"
    }
  }
}

locals {
  cluster_name = "aws-eks-ent-multi-az-cluster-prod"
  
  common_tags = {
    Environment = "prod"
    Project     = "aws-eks-ent-multi-az-cluster"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"
  
  cluster_name = local.cluster_name
  vpc_cidr     = "10.1.0.0/16"
  
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  
  tags = local.common_tags
}

module "security" {
  source = "../../modules/security"
  
  cluster_name         = local.cluster_name
  vpc_id              = module.vpc.vpc_id
  allowed_cidr_blocks = ["10.1.0.0/16"]
  
  tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"
  
  cluster_name               = local.cluster_name
  kubernetes_version         = "1.28"
  private_subnet_ids         = module.vpc.private_subnet_ids
  public_subnet_ids          = module.vpc.public_subnet_ids
  cluster_security_group_id  = module.security.cluster_security_group_id
  kms_key_arn               = module.security.kms_key_arn
  
  node_instance_types = ["m5.large", "m5a.large"]
  node_desired_size   = 6
  node_max_size       = 12
  node_min_size       = 3
  node_disk_size      = 50
  
  tags = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  cluster_name       = local.cluster_name
  aws_region         = var.aws_region
  log_retention_days = 90
  kms_key_arn        = module.security.kms_key_arn
  tags               = local.common_tags
}

module "backup" {
  source = "../../modules/backup"

  cluster_name = local.cluster_name
  kms_key_arn  = module.security.kms_key_arn
  tags         = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  cluster_name = local.cluster_name
  kms_key_arn  = module.security.kms_key_arn
  tags         = local.common_tags
}

module "logging" {
  source = "../../modules/logging"

  cluster_name       = local.cluster_name
  log_retention_days = 90
  kms_key_arn        = module.security.kms_key_arn
  tags               = local.common_tags
}

module "disaster_recovery" {
  source = "../../modules/disaster-recovery"

  cluster_name = local.cluster_name
  kms_key_arn  = module.security.kms_key_arn
  tags         = local.common_tags
}

module "cost_optimization" {
  source = "../../modules/cost-optimization"

  cluster_name      = local.cluster_name
  node_role_arn     = module.eks.node_group_role_arn
  subnet_ids        = module.vpc.private_subnet_ids
  spot_desired_size = 4
  spot_max_size     = 20
  spot_min_size     = 2
  tags              = local.common_tags
}# Updated 20251109_123803
