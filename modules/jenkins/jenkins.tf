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
        templatefile("${path.module}/secrets.yaml.tpl", {
          jenkins_admin_username = var.jenkins_admin_username
          jenkins_admin_password = var.jenkins_admin_password
          github_username        = var.github_username
          github_token           = var.github_token
          git_repo_url           = var.git_repo_url
          git_branch             = var.git_branch
          ecr_registry           = var.ecr_registry
          ecr_repo               = var.ecr_repo
        })
    ]

    set {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.jenkins_agent.arn
    }

    depends_on = [kubernetes_annotations.gp2_default]
}