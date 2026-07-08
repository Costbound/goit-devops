controller:
  admin:
    username: ${jenkins_admin_username}
    password: ${jenkins_admin_password}
  additionalEnvs:
    - name: GIT_REPO_URL
      value: "${git_repo_url}"
    - name: GIT_BRANCH
      value: "${git_branch}"
  JCasC:
    configScripts:
      credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                  - usernamePassword:
                      scope: GLOBAL
                      id: "github-credentials"
                      username: "${github_username}"
                      password: "${github_token}"
                      description: "GitHub token for git push"
      global-env: |
        jenkins:
          globalNodeProperties:
            - envVars:
                env:
                  - key: GIT_REPO_URL
                    value: "${git_repo_url}"
                  - key: GIT_BRANCH
                    value: "${git_branch}"
                  - key: ECR_REGISTRY
                    value: "${ecr_registry}"
                  - key: ECR_REPO
                    value: "${ecr_repo}"
      pipeline-job: |
        jobs:
          - script: >
              pipelineJob('django-app') {
                definition {
                  cpsScm {
                    scm {
                      git {
                        remote {
                          url('${git_repo_url}')
                          credentials('github-credentials')
                        }
                        branch('*/${git_branch}')
                      }
                    }
                    scriptPath('Jenkinsfile')
                  }
                }
              }
