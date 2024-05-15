terraform {
  backend "s3" {
    bucket         = "my-terraform-statefile1"
    region         = "us-east-1"
    key            = "EKS-DevSecOps-terraform-Project/EKS-TF/terraform.tfstate"
    dynamodb_table = "state-info"
    encrypt        = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source  = "hashicorp/aws"
    }
  }
}
