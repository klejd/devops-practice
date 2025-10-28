terraform {
  required_version = ">= 1.5.0"

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
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "DevOps-Practice"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = var.single_nat_gateway
  enable_internet_gateway = var.enable_internet_gateway
  enable_vpc_endpoints    = var.enable_vpc_endpoints

  tags = var.tags
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  environment            = var.environment
  repository_name        = var.ecr_repository_name
  image_tag_mutability   = var.ecr_image_tag_mutability
  scan_on_push           = var.ecr_scan_on_push
  image_retention_count  = var.ecr_image_retention_count

  tags = var.tags
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  environment         = var.environment
  cluster_name        = var.eks_cluster_name
  cluster_version     = var.eks_cluster_version
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Node configuration (cheapest: t3.small)
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size
  node_disk_size      = var.eks_node_disk_size

  # Logging configuration
  enable_cluster_logging       = var.eks_enable_logging
  cluster_log_retention_days   = var.eks_log_retention_days

  tags = var.tags
}
