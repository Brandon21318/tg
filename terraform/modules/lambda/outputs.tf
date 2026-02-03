output "coordinator_function_name" {
  description = "Name of the coordinator Lambda function"
  value       = aws_lambda_function.coordinator.function_name
}

output "coordinator_function_arn" {
  description = "ARN of the coordinator Lambda function"
  value       = aws_lambda_function.coordinator.arn
}

output "worker_function_name" {
  description = "Name of the worker Lambda function"
  value       = aws_lambda_function.worker.function_name
}

output "worker_function_arn" {
  description = "ARN of the worker Lambda function"
  value       = aws_lambda_function.worker.arn
}

output "processor_function_name" {
  description = "Name of the processor Lambda function"
  value       = aws_lambda_function.processor.function_name
}

output "processor_function_arn" {
  description = "ARN of the processor Lambda function"
  value       = aws_lambda_function.processor.arn
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution.arn
}

output "schedule_rule_arn" {
  description = "ARN of the EventBridge schedule rule"
  value       = aws_cloudwatch_event_rule.scraper_schedule.arn
}

output "coordinator_log_group" {
  description = "CloudWatch log group for coordinator function"
  value       = aws_cloudwatch_log_group.coordinator.name
}

output "worker_log_group" {
  description = "CloudWatch log group for worker function"
  value       = aws_cloudwatch_log_group.worker.name
}

output "processor_log_group" {
  description = "CloudWatch log group for processor function"
  value       = aws_cloudwatch_log_group.processor.name
}
