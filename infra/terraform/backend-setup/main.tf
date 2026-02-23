# This file creates the S3 backend for storing Terraform state
# Run this FIRST before running the main infrastructure

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "backend" {
  source = "../modules/terraform-state"

  project_name = var.project_name
}
