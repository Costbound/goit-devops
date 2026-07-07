resource "kubernetes_annotations" "gp2_default" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }
}

resource "helm_release" "jenkins" {
    name             = "jenkins"
    namespace        = "jenkins"
    create_namespace = true
    repository       = "https://charts.jenkins.io"
    chart            = "jenkins"
    version          = "5.9.32"
    timeout          = 600
    wait             = true

    values = [
        file("${path.module}/values.yaml"),
        file("${path.module}/secrets.yaml")
    ]

    depends_on = [kubernetes_annotations.gp2_default]
}