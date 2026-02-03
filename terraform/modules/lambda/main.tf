# Lambda Functions Module
# Creates Lambda functions for news scraping orchestration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  function_prefix = "${var.app_name}-${var.environment}"
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_execution" {
  name = "${local.function_prefix}-lambda-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy (if Lambda is in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Policy for Lambda to invoke other Lambdas
resource "aws_iam_role_policy" "lambda_invoke" {
  name = "${local.function_prefix}-lambda-invoke"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:InvokeAsync"
        ]
        Resource = "arn:aws:lambda:${var.aws_region}:*:function:${local.function_prefix}-*"
      }
    ]
  })
}

# Policy for Secrets Manager access
resource "aws_iam_role_policy" "secrets_access" {
  name = "${local.function_prefix}-secrets-access"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      }
    ]
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "coordinator" {
  name              = "/aws/lambda/${local.function_prefix}-scraper-coordinator"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/aws/lambda/${local.function_prefix}-scraper-worker"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${local.function_prefix}-article-processor"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda Function: Scraper Coordinator
resource "aws_lambda_function" "coordinator" {
  filename         = var.coordinator_zip_path
  function_name    = "${local.function_prefix}-scraper-coordinator"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "bootstrap"
  source_code_hash = filebase64sha256(var.coordinator_zip_path)
  runtime         = "provided.al2023"
  architectures   = ["x86_64"]
  timeout         = var.coordinator_timeout
  memory_size     = var.coordinator_memory

  environment {
    variables = merge(
      var.environment_variables,
      {
        WORKER_FUNCTION_NAME = aws_lambda_function.worker.function_name
        DB_HOST              = var.database_endpoint
        ENVIRONMENT          = var.environment
      }
    )
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.coordinator,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = merge(
    var.tags,
    {
      Function = "coordinator"
    }
  )
}

# Lambda Function: Scraper Worker
resource "aws_lambda_function" "worker" {
  filename         = var.worker_zip_path
  function_name    = "${local.function_prefix}-scraper-worker"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "bootstrap"
  source_code_hash = filebase64sha256(var.worker_zip_path)
  runtime         = "provided.al2023"
  architectures   = ["x86_64"]
  timeout         = var.worker_timeout
  memory_size     = var.worker_memory

  environment {
    variables = merge(
      var.environment_variables,
      {
        DB_HOST     = var.database_endpoint
        ENVIRONMENT = var.environment
      }
    )
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.worker,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = merge(
    var.tags,
    {
      Function = "worker"
    }
  )
}

# Lambda Function: Article Processor
resource "aws_lambda_function" "processor" {
  filename         = var.processor_zip_path
  function_name    = "${local.function_prefix}-article-processor"
  role            = aws_iam_role.lambda_execution.arn
  handler         = "bootstrap"
  source_code_hash = filebase64sha256(var.processor_zip_path)
  runtime         = "provided.al2023"
  architectures   = ["x86_64"]
  timeout         = var.processor_timeout
  memory_size     = var.processor_memory

  environment {
    variables = merge(
      var.environment_variables,
      {
        DB_HOST     = var.database_endpoint
        ENVIRONMENT = var.environment
      }
    )
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.processor,
    aws_iam_role_policy_attachment.lambda_basic,
  ]

  tags = merge(
    var.tags,
    {
      Function = "processor"
    }
  )
}

# EventBridge Rule: Schedule coordinator to run daily
resource "aws_cloudwatch_event_rule" "scraper_schedule" {
  name                = "${local.function_prefix}-scraper-schedule"
  description         = "Trigger scraper coordinator ${var.schedule_expression}"
  schedule_expression = var.schedule_expression
  is_enabled         = var.schedule_enabled

  tags = var.tags
}

# EventBridge Target: Invoke coordinator Lambda
resource "aws_cloudwatch_event_target" "coordinator" {
  rule      = aws_cloudwatch_event_rule.scraper_schedule.name
  target_id = "ScraperCoordinator"
  arn       = aws_lambda_function.coordinator.arn

  input = jsonencode({
    max_concurrent = var.max_concurrent_scrapers
  })
}

# Permission for EventBridge to invoke coordinator
resource "aws_lambda_permission" "eventbridge_coordinator" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.coordinator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scraper_schedule.arn
}

# Lambda Concurrency Limits (optional)
resource "aws_lambda_function_event_invoke_config" "worker" {
  function_name          = aws_lambda_function.worker.function_name
  maximum_retry_attempts = 1

  destination_config {
    on_failure {
      destination = var.dlq_arn != null ? var.dlq_arn : null
    }
  }
}
