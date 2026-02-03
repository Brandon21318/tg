terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = "newsScrape"
      ManagedBy   = "Terraform"
      Repository  = "tg"
    }
  }
}

# Local variables
locals {
  environment = "dev"
  app_name    = "newscrape"

  # Network configuration
  vpc_cidr            = "10.0.0.0/16"
  availability_zones  = ["${var.aws_region}a", "${var.aws_region}b"]

  # Common tags
  tags = {
    Environment = local.environment
    Application = local.app_name
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  environment        = local.environment
  vpc_cidr          = local.vpc_cidr
  availability_zones = local.availability_zones
  app_name          = local.app_name

  tags = local.tags
}

# Security Module
module "security" {
  source = "../../modules/security"

  environment = local.environment
  app_name    = local.app_name
  vpc_id      = module.networking.vpc_id

  tags = local.tags
}

# Database Module
module "database" {
  source = "../../modules/database"

  environment           = local.environment
  app_name              = local.app_name
  vpc_id                = module.networking.vpc_id
  database_subnet_ids   = module.networking.database_subnet_ids
  security_group_id     = module.security.rds_security_group_id

  # Dev-specific settings
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  multi_az              = false
  backup_retention_days = 7

  tags = local.tags
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  environment         = local.environment
  app_name            = local.app_name
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  ecs_security_group_id = module.security.ecs_security_group_id

  # ECS configuration
  api_image         = var.api_image
  scraper_image     = var.scraper_image
  api_cpu           = 256
  api_memory        = 512
  api_desired_count = 1

  # Database connection
  database_endpoint = module.database.endpoint
  database_name     = module.database.database_name
  db_secret_arn     = module.security.db_credentials_secret_arn

  tags = local.tags
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  environment    = local.environment
  app_name       = local.app_name
  ecs_cluster_name = module.compute.ecs_cluster_name
  alb_arn_suffix   = module.compute.alb_arn_suffix

  # Alert configuration
  alert_email = var.alert_email

  tags = local.tags
}
