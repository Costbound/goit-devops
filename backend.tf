terraform {
  backend "s3" {
    bucket       = "final-project-terraform-state-bucket-adfjhad"
    key          = "final-project/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}

