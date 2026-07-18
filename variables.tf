variable "db_user" {
  description = "PostgreSQL username for the Django app"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL password for the Django app"
  type        = string
  sensitive   = true
}

variable "django_secret_key" {
  description = "Django SECRET_KEY"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username for Jenkins credentials"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for Jenkins"
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
  description = "Git repository URL for Jenkins pipeline and Argo CD"
  type        = string
}

variable "git_branch" {
  description = "Git branch for Jenkins pipeline source"
  type        = string
  default     = "final-project"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}