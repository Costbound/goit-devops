data "kubernetes_service" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }

  depends_on = [helm_release.argocd]
}

output "argocd_url" {
  value = "https://${data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].hostname}"
}

output "argocd_namespace" {
  value = helm_release.argocd.namespace
}
