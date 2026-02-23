# Same as dev/outputs.tf but for production environment

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "backend_ecr_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr.backend_repository_url
}

output "frontend_ecr_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr.frontend_repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "db_password_secret_arn" {
  description = "ARN of the database password secret in Secrets Manager"
  value       = module.rds.db_password_secret_arn
}

output "jwt_secret_arn" {
  description = "ARN of the JWT secret in Secrets Manager"
  value       = module.ecs.jwt_secret_arn
}

output "connection_instructions" {
  description = "Instructions for accessing the application"
  value = <<-EOT
  
  ========================================
  CloudForge PRODUCTION Infrastructure
  ========================================
  
  Application URL: http://${module.alb.alb_dns_name}
  
  ⚠️ PRODUCTION ENVIRONMENT - Handle with care!
  
  Next Steps:
  1. Configure Route 53 for custom domain
  2. Setup ACM certificate for HTTPS
  3. Update ALB listener to use HTTPS
  4. Configure CloudWatch alarms
  5. Setup automated backups
  
  ECR Repositories:
  - Backend:  ${module.ecr.backend_repository_url}
  - Frontend: ${module.ecr.frontend_repository_url}
  
  EOT
}
