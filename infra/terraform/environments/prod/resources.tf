# This file is identical to dev/resources.tf
# Production uses different variable values (see terraform.tfvars.example)

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name          = var.project_name
  cidr_block            = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
}

# Security Groups Module
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  private_subnet_ids     = module.vpc.private_subnet_ids
  rds_security_group_id  = module.security.rds_sg_id
  
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  engine_version         = var.db_engine_version
  database_name          = var.db_name
  master_username        = var.db_username
  
  skip_final_snapshot    = var.db_skip_final_snapshot
  deletion_protection    = var.db_deletion_protection
  multi_az               = var.db_multi_az
}

# Application Load Balancer Module
module "alb" {
  source = "../../modules/alb"

  project_name           = var.project_name
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  alb_security_group_id  = module.security.alb_sg_id
  
  enable_deletion_protection = var.alb_deletion_protection
}

# ECS Fargate Module
module "ecs" {
  source = "../../modules/ecs"

  project_name              = var.project_name
  aws_region                = var.aws_region
  private_subnet_ids        = module.vpc.private_subnet_ids
  ecs_security_group_id     = module.security.ecs_tasks_sg_id
  
  backend_target_group_arn  = module.alb.backend_target_group_arn
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  alb_listener_arn          = module.alb.listener_arn
  
  backend_image             = module.ecr.backend_repository_url
  backend_image_tag         = var.backend_image_tag
  frontend_image            = module.ecr.frontend_repository_url
  frontend_image_tag        = var.frontend_image_tag
  
  backend_cpu               = var.backend_cpu
  backend_memory            = var.backend_memory
  frontend_cpu              = var.frontend_cpu
  frontend_memory           = var.frontend_memory
  
  backend_desired_count     = var.backend_desired_count
  frontend_desired_count    = var.frontend_desired_count
  
  db_username               = var.db_username
  db_address                = module.rds.db_address
  db_port                   = tostring(module.rds.db_port)
  db_name                   = var.db_name
  db_password_secret_arn    = module.rds.db_password_secret_arn
}
