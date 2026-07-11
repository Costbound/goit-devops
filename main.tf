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
  ecr_name    = "lesson-8-9/django-app"
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
  source            = "./modules/jenkins"
  cluster_name      = module.eks.eks_cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  github_username        = var.github_username
  github_token           = var.github_token
  jenkins_admin_username = var.jenkins_admin_username
  jenkins_admin_password = var.jenkins_admin_password
  git_repo_url           = var.git_repo_url
  git_branch             = var.git_branch
  ecr_registry           = split("/", module.ecr.repository_url)[0]
  ecr_repo               = join("/", slice(split("/", module.ecr.repository_url), 1, length(split("/", module.ecr.repository_url))))

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}

module "argo_cd" {
  source            = "./modules/argo_cd"
  cluster_name      = module.eks.eks_cluster_name
  db_user           = var.db_user
  db_password       = var.db_password
  django_secret_key = var.django_secret_key
  repo_url          = var.git_repo_url

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}