output "jenkins_release_name" {
    value = helm_release.jenkins.name
}

output "jenkins_namespace" {
    value = helm_release.jenkins.namespace
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = helm_release.jenkins.namespace
  }

  depends_on = [helm_release.jenkins]
}

output "jenkins_url" {
  value = "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}"
}