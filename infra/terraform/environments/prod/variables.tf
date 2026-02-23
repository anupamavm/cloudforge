# This file is identical to dev/variables.tf
# Copy from dev/variables.tf or create symlink
# Production uses different default values

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloudforge-prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"  # Different from dev
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"  # Production tier
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100  # More storage for production
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "cloudforge"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false  # Keep snapshots in production
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true  # Enabled for production
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true  # Enabled for production HA
}

variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = true  # Enabled for production
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = string
  default     = "512"  # 0.5 vCPU for production
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = string
  default     = "1024"  # 1GB for production
}

variable "frontend_cpu" {
  description = "CPU units for frontend task"
  type        = string
  default     = "512"  # 0.5 vCPU for production
}

variable "frontend_memory" {
  description = "Memory for frontend task in MB"
  type        = string
  default     = "1024"  # 1GB for production
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 2  # Multiple instances for HA
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 2  # Multiple instances for HA
}
