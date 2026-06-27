# GoIT DevOps — Lesson 7: Terraform AWS Infrastructure

## Project Structure

```
.
├── backend.tf          # S3 remote backend configuration
├── main.tf             # Root module — calls all child modules
├── outputs.tf          # Root-level outputs
└── modules/
    ├── s3-backend/     # S3 bucket + DynamoDB for Terraform state
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/            # VPC, subnets, IGW, NAT Gateway, route tables
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ecr/            # ECR repository with scanning and access policy
        ├── ecr.tf
        ├── variables.tf
        └── output.tf
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- AWS CLI configured with credentials (`aws configure`)
- Sufficient IAM permissions (S3, DynamoDB, VPC, ECR)

## Commands

### First-time setup (create S3 backend resources first)

The S3 bucket and DynamoDB table must exist before using them as a backend.
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
- **DynamoDB table** — provides state locking to prevent concurrent modifications

| Variable      | Description                     |
| ------------- | ------------------------------- |
| `bucket_name` | Name of the S3 bucket           |
| `table_name`  | Name of the DynamoDB lock table |

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
