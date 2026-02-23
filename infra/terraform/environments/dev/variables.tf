variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "cloudforge-dev"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# RDS Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"  # Free tier eligible
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
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
  description = "Skip final snapshot when destroying (dev only)"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false  # Disabled for dev
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false  # Disabled for dev to save costs
}

# ALB Variables
variable "alb_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false  # Disabled for dev
}

# ECS Variables
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
  description = "CPU units for backend task (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = string
  default     = "512"
}

variable "frontend_cpu" {
  description = "CPU units for frontend task (256 = 0.25 vCPU)"
  type        = string
  default     = "256"
}

variable "frontend_memory" {
  description = "Memory for frontend task in MB"
  type        = string
  default     = "512"
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}
