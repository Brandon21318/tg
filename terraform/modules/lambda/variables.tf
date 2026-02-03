variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "coordinator_zip_path" {
  description = "Path to coordinator Lambda deployment package"
  type        = string
}

variable "worker_zip_path" {
  description = "Path to worker Lambda deployment package"
  type        = string
}

variable "processor_zip_path" {
  description = "Path to processor Lambda deployment package"
  type        = string
}

variable "database_endpoint" {
  description = "RDS database endpoint"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing database credentials"
  type        = string
}

variable "vpc_config" {
  description = "VPC configuration for Lambda functions"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "environment_variables" {
  description = "Environment variables for Lambda functions"
  type        = map(string)
  default     = {}
}

variable "coordinator_timeout" {
  description = "Coordinator Lambda timeout in seconds"
  type        = number
  default     = 300 # 5 minutes
}

variable "coordinator_memory" {
  description = "Coordinator Lambda memory in MB"
  type        = number
  default     = 256
}

variable "worker_timeout" {
  description = "Worker Lambda timeout in seconds"
  type        = number
  default     = 900 # 15 minutes
}

variable "worker_memory" {
  description = "Worker Lambda memory in MB"
  type        = number
  default     = 512
}

variable "processor_timeout" {
  description = "Processor Lambda timeout in seconds"
  type        = number
  default     = 300 # 5 minutes
}

variable "processor_memory" {
  description = "Processor Lambda memory in MB"
  type        = number
  default     = 256
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g., 'cron(0 6 * * ? *)' for 6 AM UTC daily)"
  type        = string
  default     = "cron(0 6 * * ? *)" # 6 AM UTC daily
}

variable "schedule_enabled" {
  description = "Whether the scraper schedule is enabled"
  type        = bool
  default     = true
}

variable "max_concurrent_scrapers" {
  description = "Maximum number of concurrent scraper workers"
  type        = number
  default     = 10
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 7
}

variable "dlq_arn" {
  description = "ARN of Dead Letter Queue (SQS) for failed invocations"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
