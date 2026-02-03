variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "api_image" {
  description = "Docker image for API service"
  type        = string
  default     = "newscrape/api:latest"
}

variable "scraper_image" {
  description = "Docker image for scraper service"
  type        = string
  default     = "newscrape/scraper:latest"
}

variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}

variable "db_master_password" {
  description = "Master password for RDS (will be stored in Secrets Manager)"
  type        = string
  sensitive   = true
}
