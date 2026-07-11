module "s3_backend" {
  source      = "./modules/s3-backend"
  bucket_name = "lesson-db-module-terraform-state-bucket-adfjhad"
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_name           = "lesson-db-module-vpc"
  cluster_name       = "lesson-db-module-eks-cluster"
}

module "ecr" {
  source      = "./modules/ecr"
  ecr_name    = "lesson-db-module/django-app"
  scan_on_push = true
}
module "eks" {
  source          = "./modules/eks"
  cluster_name    = "lesson-db-module-eks-cluster"
  subnet_ids      = module.vpc.private_subnets
  node_group_name = "lesson-db-module-node-group"
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
  db_host           = module.rds.endpoint
  db_user           = var.db_user
  db_password       = var.db_password
  django_secret_key = var.django_secret_key
  repo_url          = var.git_repo_url

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}

module "rds" {
  source = "./modules/rds"

  name                       = "lesson-db-module-db"
  use_aurora                 = false
  aurora_instance_count      = 2

  # --- RDS-only ---
  engine                     = "postgres"
  engine_version             = "18.4"
  parameter_group_family_rds = "postgres18"

  # Common
  instance_class             = "db.t3.medium"
  allocated_storage          = 20
  db_name                    = "django_db"
  username                   = var.db_user
  password                   = var.db_password
  subnet_private_ids         = module.vpc.private_subnets
  subnet_public_ids          = module.vpc.public_subnets
  publicly_accessible        = false
  allowed_cidr_blocks        = ["10.0.0.0/16"]
  vpc_id                     = module.vpc.vpc_id
  multi_az                   = false  # dev setting — no need for Multi-AZ
  backup_retention_period    = 7
  parameters = {
    max_connections              = "200"
    log_min_duration_statement   = "500"
  }

  tags = {
    Environment = "dev"
    Project     = "lesson-db-module"
  }
} 