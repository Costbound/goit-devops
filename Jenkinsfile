pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - /busybox/cat
    tty: true
    resources:
      requests:
        cpu: 500m
        memory: 1Gi
      limits:
        cpu: "1"
        memory: 2Gi
"""
        }
    }

    environment {
        ECR_REGISTRY  = "615299736927.dkr.ecr.us-east-1.amazonaws.com"
        ECR_REPO      = "lesson7/django-app"
        IMAGE_TAG     = "${env.GIT_COMMIT[0..6]}"
    }

    stages {
        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=\$(pwd)/django-app \
                            --dockerfile=\$(pwd)/django-app/Dockerfile \
                            --destination=${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} \
                            --destination=${ECR_REGISTRY}/${ECR_REPO}:latest
                    """
                }
            }
        }

        stage('Update Image Tag in values.yaml') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-credentials',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins"
                        git remote set-url origin https://\${GIT_USER}:\${GIT_TOKEN}@\${GIT_REPO_URL#https://}
                        git fetch origin main
                        git checkout -B main origin/main
                        git checkout origin/lesson-8-9 -- charts/django-app/templates/ charts/django-app/Chart.yaml
                        sed -i 's|tag:.*|tag: "${IMAGE_TAG}"|' charts/django-app/values.yaml
                        git add charts/django-app/
                        git commit -m "ci: update django-app image tag to ${IMAGE_TAG} and sync chart templates"
                        git push origin main
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Check logs above."
        }
    }
}
