# GoIT DevOps — Final Project: CI/CD on AWS EKS

Full GitOps setup on AWS EKS using Terraform, Jenkins, and Argo CD, with cluster observability via Prometheus and Grafana.

## Architecture

```
git push → final-project
    └─► Jenkins (Kaniko build → ECR push)
            └─► updates charts/django-app/values.yaml on main
                    └─► Argo CD detects change → deploys to EKS

Prometheus + Grafana (kube-prometheus-stack)
    └─► scrapes cluster/node/pod metrics
            └─► Grafana dashboards for cluster health & resource usage
```

| Component      | Role                                                                                                        |
| -------------- | ----------------------------------------------------------------------------------------------------------- |
| **Jenkins**    | Builds Docker image in-cluster (Kaniko), pushes to ECR, commits updated `values.yaml` to `main`             |
| **Argo CD**    | Watches `main` branch, auto-syncs `charts/django-app` to the `django-app` namespace                         |
| **Prometheus** | Scrapes and stores cluster, node, and pod metrics (via kube-prometheus-stack)                               |
| **Grafana**    | Visualizes metrics from Prometheus via pre-built and custom dashboards                                      |
| **ECR**        | Private Docker registry hosted on AWS                                                                       |
| **IRSA**       | Jenkins pod gets IAM role via ServiceAccount — no static AWS credentials needed                             |
| **Secrets**    | All sensitive values in `terraform.tfvars` (gitignored), injected via `templatefile()` at `terraform apply` |

---

## Project Structure

```
.
├── backend.tf                  # S3 remote state backend
├── main.tf                     # Root module — wires all child modules
├── variables.tf                # Input variable declarations
├── outputs.tf                  # Root-level outputs (URLs, IDs)
├── providers.tf                # AWS, Helm, Kubernetes providers
├── terraform.tfvars            # All secrets — gitignored, never committed
├── terraform.tfvars.example    # Template showing required variables
├── Jenkinsfile                 # CI pipeline definition
├── django-app/                 # Django application source
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── hw4/settings.py         # Reads all config from environment variables
│   └── nginx/nginx.conf
├── charts/
│   └── django-app/             # Helm chart — deployed by Argo CD from main
│       ├── values.yaml         # image.repository + image.tag updated by CI
│       └── templates/
│           ├── deployment.yaml # envFrom: ConfigMap + secretRef
│           ├── configmap.yaml  # Non-sensitive env vars only
│           ├── service.yaml    # LoadBalancer (port 80 → 8000)
│           └── hpa.yaml        # HPA: 2–6 pods at >70% CPU
└── modules/
    ├── s3-backend/             # S3 bucket + locking for Terraform state
    ├── vpc/                    # VPC, subnets, IGW, NAT Gateway, route tables
    ├── ecr/                    # ECR repository
    ├── eks/                    # EKS cluster, node group, OIDC, EBS CSI driver
    ├── rds/                    # Universal RDS module (standalone or Aurora), subnet group, SG, parameter group
    ├── jenkins/                # Jenkins Helm release + IRSA role for ECR push
    ├── argo_cd/                # Argo CD Helm release, Application CRD, k8s secret
    └── monitoring/             # kube-prometheus-stack Helm release (Prometheus, Grafana, Alertmanager)
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) — configured with sufficient IAM permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- IAM permissions: S3, VPC, ECR, EKS, IAM (OIDC, roles, policies)

---

## Setup

### 1. Create `terraform.tfvars`

Copy the example file and fill in real values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

All variables that must be set:

```hcl
db_user           = "django_user"
db_password       = "..."
django_secret_key = "..."

github_username        = "your-github-username"
github_token           = "ghp_..."

jenkins_admin_username = "admin"
jenkins_admin_password = "..."

git_repo_url = "https://github.com/your-org/your-repo.git"
git_branch   = "final-project"

grafana_admin_password = "..."
```

### 2. Bootstrap S3 backend (first time only)

The S3 bucket must exist before `terraform init` can use it as a backend.

```bash
# Temporarily comment out backend.tf, then:
terraform init
terraform apply -target=module.s3_backend

# Uncomment backend.tf, then migrate state to S3:
terraform init -migrate-state
```

### 3. Deploy everything

```bash
terraform apply
```

This provisions: VPC → ECR → EKS → Jenkins → Argo CD → Kubernetes secret for DB credentials → Prometheus/Grafana (monitoring).

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name final-project-eks-cluster
```

### 5. Get service URLs

```bash
terraform output
```

Jenkins, Argo CD, and Grafana are exposed via AWS LoadBalancer. It may take 1–2 minutes for hostnames to resolve after `apply`.

### 6. Get Argo CD credentials

**Username:** `admin`

**Password** — retrieve the auto-generated initial password from the cluster secret:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### 7. Access Grafana

**Username:** `admin`

**Password:** the value you set for `grafana_admin_password` in `terraform.tfvars`.

Via the LoadBalancer URL:

```bash
terraform output grafana_url
```

Or via port-forward (service name depends on Helm release, default is `<release-name>-grafana`):

```bash
kubectl get svc -n monitoring
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
```

Then open `http://localhost:3000`. Default Kubernetes dashboards (Cluster, Nodes, Pods, Compute Resources) are pre-loaded and backed by the bundled Prometheus datasource.

### 8. Monitoring & checking metrics

Confirm Prometheus is scraping all expected targets:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
```

Open `http://localhost:9090/targets` to verify targets are `UP`.

In Grafana, verify metrics are flowing by opening one of the default dashboards (e.g. **Kubernetes / Compute Resources / Cluster**) and confirming panels are populated.

---

## CI/CD Flow

1. Push code to `final-project` branch
2. Jenkins pipeline triggers (manually or via webhook):
   - Kaniko builds the Docker image inside the cluster
   - Image pushed to ECR with tag = first 7 chars of commit SHA + `latest`
   - Jenkins fetches `main`, updates `charts/django-app/values.yaml` with the new image repository and tag
   - Commits and pushes to `main`
3. Argo CD detects the change on `main` and syncs the `django-app` Helm release to the cluster

---

## Secrets Management

No secrets are stored in git. The flow is:

```
terraform.tfvars (gitignored)
    └─► templatefile("secrets.yaml.tpl")  ← committed, contains ${placeholders}
            └─► Helm values at apply time
                    └─► Jenkins JCasC (GitHub token, admin password, ECR env vars)

terraform.tfvars
    └─► kubernetes_secret "django-app-secrets"
            └─► DB pods + Django deployment (via secretRef / secretKeyRef)

terraform.tfvars
    └─► grafana_admin_password
            └─► Helm values at apply time (modules/monitoring)
```

Key files:

- `modules/jenkins/secrets.yaml.tpl` — Terraform template for Jenkins Helm secrets values
- `modules/argo_cd/secrets.tf` — creates `django-app-secrets` Kubernetes secret
- `modules/monitoring/values.yaml` — Prometheus/Grafana/Alertmanager Helm configuration
- `charts/django-app/templates/deployment.yaml` — mounts secret via `secretRef`
- `charts/django-app/templates/db.yaml` — mounts credentials via `secretKeyRef`

---

## Destroy

### Why a plain `terraform destroy` gets stuck

Several things happen outside of Terraform's knowledge when Kubernetes `LoadBalancer` services exist:

1. The **django-app service** (`charts/django-app/templates/service.yaml`) creates an AWS load balancer via the cloud controller. When Terraform deletes the `django-app` namespace, Kubernetes stalls in "Terminating" waiting for that LB to be removed from AWS.
2. The **Grafana service** (`modules/monitoring`) is also a `LoadBalancer`, so it holds its own ENIs in the same way and must be cleaned up before the VPC/subnets can be destroyed.
3. This blocks the Argo CD and monitoring Helm releases from uninstalling, which blocks the EKS cluster from being deleted, which leaves VPC subnets stuck because the LBs still hold ENIs in them.

The deadlock chain:

```
django-app LoadBalancer service ─┐
Grafana LoadBalancer service ────┤
    ├─► hold ENIs in public subnets (subnets/IGW stuck for 20+ min)
    └─► keep django-app / monitoring namespaces in "Terminating"
            └─► blocks argocd / monitoring Helm release destruction
                    └─► blocks EKS cluster deletion
```

### Safe destroy sequence

```bash
# Step 1: remove the Argo CD Application — this cascades deletion of all django-app
# resources including the LoadBalancer service, triggering AWS LB cleanup
terraform destroy -target=module.argo_cd.helm_release.argocd_config

# Step 2: remove the monitoring stack — this deletes the Grafana LoadBalancer service
# and triggers AWS LB cleanup for it as well
terraform destroy -target=module.monitoring

# Step 3: wait ~60s for AWS to finish deleting the load balancers

# Step 4: destroy remaining Helm releases (Jenkins + Argo CD controller)
terraform destroy -target=module.jenkins -target=module.argo_cd

# Step 5: destroy everything else
terraform destroy
```

---

## Modules

| Module       | Description                                                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `s3-backend` | S3 bucket with versioning and server-side encryption for Terraform state                                                        |
| `vpc`        | VPC with 3 public + 3 private subnets across 3 AZs, IGW, NAT Gateway                                                            |
| `ecr`        | ECR repository with `scan_on_push` enabled                                                                                      |
| `eks`        | EKS cluster (1.31), managed node group (t3.medium, 2–3 nodes), OIDC provider, EBS CSI driver                                    |
| `rds`        | Universal RDS module — supports standalone PostgreSQL/MySQL instance or Aurora cluster, with subnet group, SG, parameter group  |
| `jenkins`    | Jenkins via Helm (chart 5.9.32), JCasC auto-config, IRSA role with ECR push permissions                                         |
| `argo_cd`    | Argo CD via Helm (chart 7.7.0), Application CRD pointing at `charts/django-app` on `main`                                       |
| `monitoring` | kube-prometheus-stack via Helm — Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics for cluster observability |
