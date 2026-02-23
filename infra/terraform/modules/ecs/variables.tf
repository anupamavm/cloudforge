variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "backend_image" {
  description = "Docker image URL for backend"
  type        = string
}

variable "backend_image_tag" {
  description = "Docker image tag for backend"
  type        = string
  default     = "latest"
}

variable "frontend_image" {
  description = "Docker image URL for frontend"
  type        = string
}

variable "frontend_image_tag" {
  description = "Docker image tag for frontend"
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  description = "CPU units for backend task"
  type        = string
  default     = "256"
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = string
  default     = "512"
}

variable "frontend_cpu" {
  description = "CPU units for frontend task"
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

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_address" {
  description = "Database address"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_password_secret_arn" {
  description = "ARN of the database password secret"
  type        = string
}
