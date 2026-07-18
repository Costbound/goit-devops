output "monitoring_namespace" {
  value = helm_release.kube_prometheus_stack.namespace
}

data "kubernetes_service" "grafana" {
  metadata {
    name      = "monitoring-grafana"
    namespace = helm_release.kube_prometheus_stack.namespace
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

output "grafana_url" {
  value = "http://${data.kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname}"
}