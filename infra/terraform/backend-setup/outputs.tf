output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.backend.dynamodb_table_name
}

output "next_steps" {
  description = "Instructions for enabling remote state"
  value = <<-EOT
  
  ========================================
  Backend Setup Complete!
  ========================================
  
  S3 Bucket: ${module.backend.s3_bucket_name}
  DynamoDB Table: ${module.backend.dynamodb_table_name}
  
  Next Steps:
  1. Navigate to infra/terraform/environments/dev/
  2. Uncomment the backend configuration in main.tf
  3. Update the bucket name to: ${module.backend.s3_bucket_name}
  4. Run: terraform init -migrate-state
  
  This will move your state to S3 with locking enabled.
  
  EOT
}
