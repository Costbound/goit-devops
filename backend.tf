terraform {
  backend "s3" {
    bucket         = "lesson5-terraform-state-bucket-adfjhad"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "lesson5-terraform-state-lock-table"
    encrypt        = true
  }
}

