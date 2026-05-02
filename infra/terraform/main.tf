terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "platform-ops-portfolio"
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}

# ── VPC ───────────────────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project          = var.project
  environment      = terraform.workspace
  vpc_cidr         = var.vpc_cidr
  azs              = var.availability_zones
  public_subnets   = var.public_subnet_cidrs
  private_subnets  = var.private_subnet_cidrs
}

# ── ECR ───────────────────────────────────────────────────────────────────────
module "ecr" {
  source = "./modules/ecr"

  project     = var.project
  environment = terraform.workspace
}

# ── EKS ───────────────────────────────────────────────────────────────────────
module "eks" {
  source = "./modules/eks"

  project            = var.project
  environment        = terraform.workspace
  cluster_version    = var.eks_cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  depends_on = [module.vpc]
}

# ── RDS (optional – free-tier compatible) ─────────────────────────────────────
module "rds" {
  source = "./modules/rds"
  count  = var.enable_rds ? 1 : 0

  project            = var.project
  environment        = terraform.workspace
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_password        = var.db_password

  depends_on = [module.vpc]
}
