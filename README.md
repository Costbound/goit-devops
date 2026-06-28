# GoIT DevOps — Lesson 7: Terraform AWS Infrastructure

## Project Structure

```
.
├── backend.tf          # S3 remote backend configuration
├── main.tf             # Root module — calls all child modules
├── outputs.tf          # Root-level outputs
├── django-app/         # Django application source code
│   ├── Dockerfile
│   ├── manage.py
│   ├── requirements.txt
│   ├── hello/          # Example Django app
│   └── hw4/            # Django project settings
├── charts/
│   └── django-app/     # Helm chart for deploying to EKS
└── modules/
    ├── s3-backend/     # S3 bucket for Terraform state
    │   ├── s3.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/            # VPC, subnets, IGW, NAT Gateway, route tables
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ecr/            # ECR repository with scanning and access policy
    │   ├── ecr.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eks/            # EKS cluster and managed node group
        ├── eks.tf
        ├── node.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with credentials (`aws configure`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3
- [Docker](https://docs.docker.com/get-docker/) (for building and pushing the Django image)
- Sufficient IAM permissions (S3, VPC, ECR, EKS)

## Commands

### First-time setup (create S3 backend resources first)

The S3 bucket must exist before using it as a backend.
Comment out the `backend "s3"` block in `backend.tf`, run `terraform apply` to create the
`s3_backend` module resources, then uncomment the backend block and run `terraform init` again.

### Initialize

```bash
terraform init
```

### Preview changes

```bash
terraform plan
```

### Apply changes

```bash
terraform apply
```

### Destroy infrastructure

```bash
terraform destroy
```

## Modules

### `s3-backend`

Creates the remote backend infrastructure for storing Terraform state:

- **S3 bucket** — stores the `terraform.tfstate` file with versioning enabled
- **S3 encryption** — AES-256 server-side encryption enforced at bucket level
- **S3 public access block** — all public access blocked
- **S3 native locking** — `use_lockfile = true` prevents concurrent state modifications (no DynamoDB needed)

| Variable      | Description             |
| ------------- | ----------------------- |
| `bucket_name` | Name of the S3 bucket   |

### `vpc`

Builds the full network infrastructure:

- **VPC** — isolated network with custom CIDR block and DNS support enabled
- **3 public subnets** — one per availability zone, auto-assign public IPs
- **3 private subnets** — one per availability zone, no public IPs
- **Internet Gateway** — enables outbound internet access for public subnets
- **NAT Gateway** — allows private subnets to reach the internet without being publicly reachable
- **Route Tables** — public RT routes to IGW; private RT routes to NAT Gateway

| Variable             | Description                             |
| -------------------- | --------------------------------------- |
| `vpc_cidr_block`     | CIDR block for the VPC                  |
| `public_subnets`     | List of CIDR blocks for public subnets  |
| `private_subnets`    | List of CIDR blocks for private subnets |
| `availability_zones` | List of AZs to deploy subnets into      |
| `vpc_name`           | Name prefix for all resources           |

### `ecr`

Creates an Elastic Container Registry repository for storing Docker images:

- **ECR repository** — private repository with `MUTABLE` image tags
- **Image scanning** — automatically scans images for vulnerabilities on push
- **Repository policy** — grants push/pull access to the AWS account

| Variable       | Description                                               |
| -------------- | --------------------------------------------------------- |
| `ecr_name`     | Name of the ECR repository                                |
| `scan_on_push` | Enable automatic vulnerability scanning (default: `true`) |

**Outputs:** `repository_url` — use this with `docker push` to publish images.

### `eks`

Creates a fully managed Kubernetes cluster on AWS EKS:

- **EKS Cluster** — control plane with API authentication mode, public + private endpoint access
- **IAM Role (cluster)** — grants EKS service permission to manage AWS resources
- **Managed Node Group** — EC2 worker nodes (`t3.medium`) with auto-scaling
- **IAM Role (nodes)** — grants nodes permissions for ECR pull, CNI networking, worker policies

| Variable          | Description                          |
| ----------------- | ------------------------------------ |
| `cluster_name`    | Name of the EKS cluster              |
| `subnet_ids`      | Private subnet IDs to place nodes in |
| `node_group_name` | Name of the managed node group       |
| `instance_type`   | EC2 instance type for worker nodes   |
| `desired_size`    | Desired number of nodes              |
| `max_size`        | Maximum number of nodes              |
| `min_size`        | Minimum number of nodes              |

**Outputs:** `eks_cluster_name`, `eks_cluster_endpoint`, `eks_node_role_arn`

---

## Full Deployment Flow

Follow these steps in order to go from zero to a running app:

```bash
# 1. Provision AWS infrastructure
terraform init
terraform apply

# 2. Configure kubectl to talk to the new EKS cluster
aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster

# 3. Build and push the Django image to ECR
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker build --platform linux/amd64 -t django-app ./django-app
docker tag django-app:latest $ECR_URL:latest
docker push $ECR_URL:latest

# 4. Set up Helm secrets
cp charts/django-app/secrets.yaml.example charts/django-app/secrets.yaml
# Edit secrets.yaml — set ECR repository URL, DB user, and DB password

# 5. Install the Helm chart
helm dependency update ./charts/django-app
helm install django-app ./charts/django-app \
  -f charts/django-app/values.yaml \
  -f charts/django-app/secrets.yaml

# 6. Verify
kubectl get pods
kubectl get svc django-app-django   # EXTERNAL-IP is the Load Balancer DNS
```

---

## Helm Chart — `charts/django-app`

Deploys the Django application to the EKS cluster.

### Chart structure

```
charts/django-app/
├── Chart.yaml                  # Chart metadata and dependencies
├── values.yaml                 # Non-sensitive default values (committed)
├── secrets.yaml                # Real credentials — gitignored, never committed
├── secrets.yaml.example        # Template for secrets.yaml — copy and fill in
└── templates/
    ├── deployment.yaml         # Django Deployment with envFrom ConfigMap
    ├── db.yaml                 # PostgreSQL Deployment + Service (in-cluster DB)
    ├── service.yaml            # LoadBalancer Service (port 80 → 8000)
    ├── hpa.yaml                # HPA — scales 2 to 6 pods at >70% CPU
    └── configmap.yaml          # Non-sensitive env vars for Django
```

### Dependencies

| Chart            | Purpose                                     |
| ---------------- | ------------------------------------------- |
| `metrics-server` | Required by HPA to read CPU metrics         |

### Setup secrets

```bash
cp charts/django-app/secrets.yaml.example charts/django-app/secrets.yaml
# Edit secrets.yaml — set ECR repository URL, DB user, and DB password
```

### Deploy

```bash
# 1. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name lesson-7-eks-cluster

# 2. Pull Helm dependencies
helm dependency update ./charts/django-app

# 3. Install
helm install django-app ./charts/django-app \
  -f charts/django-app/values.yaml \
  -f charts/django-app/secrets.yaml

# 4. Check status
kubectl get pods
kubectl get svc django-app-django   # EXTERNAL-IP is the Load Balancer DNS
kubectl get hpa
```

### Push Docker image to ECR

Get the ECR URL from Terraform output — no need to hardcode it:

```bash
ECR_URL=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker build --platform linux/amd64 -t django-app ./django-app
docker tag django-app:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

> **Note:** Always build with `--platform linux/amd64` when deploying to EKS from an Apple Silicon Mac.
