output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnets
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "s3_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = module.s3_backend.s3_bucket_name
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.eks_cluster_name}"
}

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = module.jenkins.jenkins_url
}

output "argocd_url" {
  description = "Argo CD web UI URL"
  value       = module.argo_cd.argocd_url
}

output "rds_endpoint" {
  description = "RDS writer endpoint"
  value       = module.rds.endpoint
}

output "rds_port" {
  description = "RDS database port"
  value       = module.rds.port
}