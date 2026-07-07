module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-8-9-terraform-state-bucket-adfjhad"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_name           = "lesson-8-9-vpc"
  cluster_name       = "lesson-8-9-eks-cluster"
}

module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "lesson7/django-app"
  scan_on_push = true
}
module "eks" {
  source          = "./modules/eks"
  cluster_name    = "lesson-8-9-eks-cluster"
  subnet_ids      = module.vpc.private_subnets
  node_group_name = "lesson-8-9-node-group"
  instance_type   = "t3.medium"
  desired_size    = 2
  max_size        = 3
  min_size        = 1
}

module "jenkins" {
  source          = "./modules/jenkins"
  cluster_name = module.eks.eks_cluster_name

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}