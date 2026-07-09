resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  timeout          = 600
  wait             = true

  values = [file("${path.module}/values.yaml")]
}

resource "helm_release" "argocd_config" {
  name      = "argocd-config"
  namespace = var.namespace
  chart     = "${path.module}/charts"
  timeout   = 120
  wait      = false

  values = [file("${path.module}/charts/values.yaml")]

  set {
    name  = "application.repoURL"
    value = var.repo_url
  }

  set {
    name  = "application.targetRevision"
    value = var.target_revision
  }

  depends_on = [helm_release.argocd, kubernetes_namespace.django_app]
}
