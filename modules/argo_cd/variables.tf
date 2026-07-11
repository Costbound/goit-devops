variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.7.0"
}

variable "repo_url" {
  description = "Git repository URL for the Argo CD Application"
  type        = string
  default     = "https://github.com/Costbound/goit-devops.git"
}

variable "target_revision" {
  description = "Git branch/tag for the Argo CD Application"
  type        = string
  default     = "main"
}

variable "db_user" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY"
  type        = string
  sensitive   = true
}
