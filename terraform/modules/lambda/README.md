# Lambda Functions Module

This module creates AWS Lambda functions for the newsScrape application scraping orchestration.

## Architecture

The module creates a serverless scraping architecture with three Lambda functions:

1. **Scraper Coordinator** - Orchestrates scraping by invoking worker Lambdas for each news source
2. **Scraper Worker** - Scrapes a single news source (invoked in parallel for multiple sources)
3. **Article Processor** - Processes articles (tagging, keyword extraction) after scraping

### Event Flow

```
EventBridge Schedule (cron)
  → Scraper Coordinator Lambda
    → Worker Lambda (source 1) ──┐
    → Worker Lambda (source 2)   │
    → Worker Lambda (source 3)   ├→ Write to RDS
    → ...                         │
    → Worker Lambda (source N) ──┘
      → Article Processor Lambda (optional, async)
```

## Features

- **Scheduled Execution**: EventBridge rule triggers coordinator on a schedule (default: 6 AM UTC daily)
- **Parallel Processing**: Coordinator invokes workers asynchronously for all sources
- **VPC Integration**: Optional VPC configuration for database access
- **Error Handling**: Dead Letter Queue support for failed invocations
- **Monitoring**: CloudWatch Logs with configurable retention
- **IAM Permissions**: Least-privilege roles with Secrets Manager access

## Usage

```hcl
module "lambda" {
  source = "../../modules/lambda"

  environment        = "dev"
  app_name           = "newscrape"
  aws_region         = "us-east-1"

  # Lambda deployment packages (build with: make lambda-all)
  coordinator_zip_path = "../../../newsScrape_go/dist/lambda/scraper-coordinator.zip"
  worker_zip_path      = "../../../newsScrape_go/dist/lambda/scraper-worker.zip"
  processor_zip_path   = "../../../newsScrape_go/dist/lambda/article-processor.zip"

  # Database configuration
  database_endpoint = module.database.endpoint
  db_secret_arn     = module.security.db_credentials_secret_arn

  # VPC configuration (for database access)
  vpc_config = {
    subnet_ids         = module.networking.private_subnet_ids
    security_group_ids = [module.security.lambda_security_group_id]
  }

  # Environment variables
  environment_variables = {
    DB_NAME       = "newscrape_db"
    DB_USER       = "newscrape_app"
    JWT_SECRET    = "your-secret-from-secrets-manager"
  }

  # Schedule configuration
  schedule_expression      = "cron(0 6 * * ? *)" # 6 AM UTC daily
  schedule_enabled         = true
  max_concurrent_scrapers  = 10

  # Resource configuration
  coordinator_timeout = 300  # 5 minutes
  coordinator_memory  = 256  # MB
  worker_timeout      = 900  # 15 minutes
  worker_memory       = 512  # MB
  processor_timeout   = 300  # 5 minutes
  processor_memory    = 256  # MB

  log_retention_days = 7

  tags = {
    Environment = "dev"
    Application = "newscrape"
  }
}
```

## Building Lambda Functions

Before deploying, build the Lambda deployment packages:

```bash
cd ../../../newsScrape_go
make lambda-all
```

This creates:
- `dist/lambda/scraper-coordinator.zip`
- `dist/lambda/scraper-worker.zip`
- `dist/lambda/article-processor.zip`

## Schedule Expressions

EventBridge supports cron and rate expressions:

**Cron expressions**:
- `cron(0 6 * * ? *)` - 6 AM UTC daily
- `cron(0 */12 * * ? *)` - Every 12 hours
- `cron(0 0 * * MON-FRI *)` - Midnight UTC weekdays only

**Rate expressions**:
- `rate(12 hours)` - Every 12 hours
- `rate(1 day)` - Every day

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| app_name | Application name | string | - | yes |
| aws_region | AWS region | string | - | yes |
| coordinator_zip_path | Path to coordinator Lambda zip | string | - | yes |
| worker_zip_path | Path to worker Lambda zip | string | - | yes |
| processor_zip_path | Path to processor Lambda zip | string | - | yes |
| database_endpoint | RDS endpoint | string | - | yes |
| db_secret_arn | Secrets Manager ARN | string | - | yes |
| vpc_config | VPC configuration | object | null | no |
| environment_variables | Environment variables | map(string) | {} | no |
| coordinator_timeout | Coordinator timeout (seconds) | number | 300 | no |
| coordinator_memory | Coordinator memory (MB) | number | 256 | no |
| worker_timeout | Worker timeout (seconds) | number | 900 | no |
| worker_memory | Worker memory (MB) | number | 512 | no |
| processor_timeout | Processor timeout (seconds) | number | 300 | no |
| processor_memory | Processor memory (MB) | number | 256 | no |
| schedule_expression | EventBridge schedule | string | cron(0 6 * * ? *) | no |
| schedule_enabled | Enable schedule | bool | true | no |
| max_concurrent_scrapers | Max concurrent workers | number | 10 | no |
| log_retention_days | CloudWatch log retention | number | 7 | no |
| dlq_arn | Dead Letter Queue ARN | string | null | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| coordinator_function_name | Coordinator Lambda function name |
| coordinator_function_arn | Coordinator Lambda ARN |
| worker_function_name | Worker Lambda function name |
| worker_function_arn | Worker Lambda ARN |
| processor_function_name | Processor Lambda function name |
| processor_function_arn | Processor Lambda ARN |
| lambda_execution_role_arn | Lambda execution IAM role ARN |
| schedule_rule_arn | EventBridge schedule rule ARN |
| coordinator_log_group | Coordinator CloudWatch log group |
| worker_log_group | Worker CloudWatch log group |
| processor_log_group | Processor CloudWatch log group |

## Manual Invocation

Test Lambda functions manually:

```bash
# Invoke coordinator
aws lambda invoke \
  --function-name newscrape-dev-scraper-coordinator \
  --payload '{"max_concurrent": 5}' \
  response.json

# Invoke worker for specific source
aws lambda invoke \
  --function-name newscrape-dev-scraper-worker \
  --payload '{"source_id": 1, "source_name": "CNN"}' \
  response.json

# Invoke processor for specific article
aws lambda invoke \
  --function-name newscrape-dev-article-processor \
  --payload '{"article_id": "uuid-here", "action": "all"}' \
  response.json
```

## Monitoring

View Lambda logs:

```bash
# Coordinator logs
aws logs tail /aws/lambda/newscrape-dev-scraper-coordinator --follow

# Worker logs
aws logs tail /aws/lambda/newscrape-dev-scraper-worker --follow

# Processor logs
aws logs tail /aws/lambda/newscrape-dev-article-processor --follow
```

## Cost Optimization

- **Memory**: Start with lower memory (256-512 MB) and increase if needed
- **Timeout**: Set appropriate timeouts to avoid unnecessary charges
- **Concurrency**: Limit concurrent executions if RDS has connection limits
- **Logs**: Use shorter retention periods for non-production environments

**Estimated Costs** (30 sources, daily scraping):
- Coordinator: ~$0.01/month
- Workers: ~$2-5/month (depends on scraping duration)
- Processor: ~$1-3/month
- CloudWatch Logs: ~$0.50-2/month

## Security

- Lambda execution role has least-privilege permissions
- Database credentials stored in Secrets Manager
- VPC configuration for private database access
- CloudWatch Logs encrypted at rest
- No public internet access when in VPC

## Troubleshooting

**Lambda timeout**:
- Increase `worker_timeout` for slow sources
- Consider using Selenium scraper in separate Lambda layer

**Database connection errors**:
- Verify VPC configuration and security groups
- Check RDS connection limits
- Ensure NAT Gateway for internet access (if needed)

**Too many concurrent connections**:
- Reduce `max_concurrent_scrapers`
- Implement connection pooling in Lambda code
- Use RDS Proxy for connection management

## Future Enhancements

- [ ] Step Functions for complex orchestration
- [ ] SQS queue for worker invocations
- [ ] Lambda Layers for shared dependencies
- [ ] Reserved concurrency for predictable performance
- [ ] X-Ray tracing for debugging
