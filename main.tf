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
  region = "us-east-1"
}

module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-7-terraform-state-bucket-adfjhad"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_name           = "lesson-7-vpc"
  cluster_name       = "lesson-7-eks-cluster"
}

module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "lesson7/django-app"
  scan_on_push = true
}
module "eks" {
  source          = "./modules/eks"
  cluster_name    = "lesson-7-eks-cluster"
  subnet_ids      = module.vpc.private_subnets
  node_group_name = "lesson-7-node-group"
  instance_type   = "t3.medium"
  desired_size    = 2
  max_size        = 3
  min_size        = 1
}
