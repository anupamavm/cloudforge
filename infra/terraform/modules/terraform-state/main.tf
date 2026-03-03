# --------------------------------------------------
# Random suffix for unique bucket name
# --------------------------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --------------------------------------------------
# S3 Bucket for Terraform State
# --------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-cloudforge-test"

  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name        = "${var.project_name}-terraform-state"
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}

# --------------------------------------------------
# Enable versioning for state recovery
# --------------------------------------------------
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------------------------------
# Server-side encryption (AES256)
# --------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --------------------------------------------------
# Block all public access
# --------------------------------------------------
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------
# Lifecycle rule to control old versions (cost control)
# --------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# --------------------------------------------------
# DynamoDB Table for State Locking
# --------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-terraform-locks"
    ManagedBy   = "Terraform"
    Environment = "shared"
  }
}