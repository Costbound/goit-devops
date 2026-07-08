variable "cluster_name" {
    description = "Name of the EKS cluster"
    type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider"
  type        = string
}

variable "github_username" {
  description = "GitHub username for Jenkins credentials"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "jenkins_admin_username" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "Git repository URL for the Jenkins pipeline"
  type        = string
}

variable "git_branch" {
  description = "Git branch for the Jenkins pipeline"
  type        = string
  default     = "lesson-8-9"
}

variable "ecr_registry" {
  description = "ECR registry hostname (account.dkr.ecr.region.amazonaws.com)"
  type        = string
}

variable "ecr_repo" {
  description = "ECR repository name"
  type        = string
}