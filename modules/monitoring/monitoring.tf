resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.12.1"
  timeout          = 300
  wait             = true
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "monitoring"
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  timeout          = 600
  wait             = true

  values = [file("${path.module}/values.yaml")]

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }
}