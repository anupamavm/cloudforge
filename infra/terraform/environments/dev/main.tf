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

  # Uncomment after creating the S3 bucket for state storage
  backend "s3" {
    bucket         = "cloudforge-terraform-state-a6586bab"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "cloudforge-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}
