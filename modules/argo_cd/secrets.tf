resource "kubernetes_namespace" "django_app" {
  metadata {
    name = "django-app"
  }
}

resource "kubernetes_secret" "django_app" {
  metadata {
    name      = "django-app-secrets"
    namespace = kubernetes_namespace.django_app.metadata[0].name
  }

  data = {
    POSTGRES_HOST     = var.db_host
    POSTGRES_USER     = var.db_user
    POSTGRES_PASSWORD = var.db_password
    SECRET_KEY        = var.django_secret_key
  }
}
