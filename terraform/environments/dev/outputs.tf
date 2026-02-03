output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "alb_url" {
  description = "Full URL of the Application Load Balancer"
  value       = "http://${module.compute.alb_dns_name}"
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecr_api_repository_url" {
  description = "URL of the ECR repository for API images"
  value       = module.compute.ecr_api_repository_url
}

output "ecr_scraper_repository_url" {
  description = "URL of the ECR repository for scraper images"
  value       = module.compute.ecr_scraper_repository_url
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.monitoring.log_group_name
}
