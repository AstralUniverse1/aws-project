terraform {
  backend "s3" {
    bucket         = "tfstate-commit-project01"
    key            = "project1/terraform.tfstate"
    region         = "il-central-1"
    dynamodb_table = "tf-lock-commit-project01"
    encrypt        = true
  }
}