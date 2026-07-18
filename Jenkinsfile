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
    env:
    - name: AWS_REGION
      value: "us-east-1"
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
        IMAGE_TAG = "${env.GIT_COMMIT[0..6]}"
    }

    stages {
        stage('Build & Push to ECR') {
            steps {
                container('kaniko') {
                    sh """
                        /kaniko/executor \
                            --context=\$(pwd)/django-app \
                            --dockerfile=\$(pwd)/django-app/Dockerfile \
                            --destination=${env.ECR_REGISTRY}/${env.ECR_REPO}:${env.IMAGE_TAG} \
                            --destination=${env.ECR_REGISTRY}/${env.ECR_REPO}:latest
                    """
                }
            }
        }

        stage('Push chart + image tag to main') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-credentials',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_TOKEN'
                )]) {
                    sh """
                        git config user.email "jenkins@ci.local"
                        git config user.name "Jenkins"
                        git remote set-url origin https://\${GIT_USER}:\${GIT_TOKEN}@${env.GIT_REPO_URL.replaceFirst('https://', '')}

                        git fetch origin main || true
                        git checkout -B main origin/main 2>/dev/null || git checkout --orphan main

                        # Sync entire charts/ from this build commit so main is never missing files
                        git checkout ${env.GIT_COMMIT} -- charts/

                        # Set correct image repository and tag
                        sed -i "s|^\\([[:space:]]*repository: \\).*|\\1${env.ECR_REGISTRY}/${env.ECR_REPO}|" charts/django-app/values.yaml
                        sed -i "s|^\\([[:space:]]*tag: \\).*|\\1\\"${env.IMAGE_TAG}\\"|" charts/django-app/values.yaml

                        git add charts/
                        if git diff --cached --quiet; then
                            echo "No changes to commit"
                        else
                            git commit -m "ci: update django-app image tag to ${env.IMAGE_TAG} [skip ci]"
                            git push origin main
                        fi
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