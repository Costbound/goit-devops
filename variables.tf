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
