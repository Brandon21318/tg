# Terraform Modules

This directory contains reusable Terraform modules for infrastructure components.

## Module Structure

Each module should follow this structure:
```
module_name/
├── main.tf       # Main resource definitions
├── variables.tf  # Input variables
├── outputs.tf    # Output values
└── README.md     # Module documentation
```

## Available Modules

### networking
Creates VPC, subnets, internet gateway, NAT gateway, and route tables.

**Resources**:
- VPC with DNS support
- Public subnets (for ALB)
- Private subnets (for ECS tasks)
- Database subnets (for RDS)
- Internet Gateway
- NAT Gateway
- Route tables and associations

**Outputs**:
- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`
- `database_subnet_ids`

### security
Manages IAM roles, security groups, and secrets.

**Resources**:
- IAM roles for ECS tasks
- Security groups (ALB, ECS, RDS)
- AWS Secrets Manager secrets
- KMS keys for encryption

**Outputs**:
- `alb_security_group_id`
- `ecs_security_group_id`
- `rds_security_group_id`
- `ecs_task_execution_role_arn`
- `db_credentials_secret_arn`

### database
Creates and configures RDS PostgreSQL database.

**Resources**:
- RDS instance
- Parameter group
- Subnet group
- Automated backups
- Read replicas (staging/production)

**Outputs**:
- `endpoint`
- `database_name`
- `port`

### compute
Manages ECS cluster, services, and Application Load Balancer.

**Resources**:
- ECS cluster
- ECS task definitions (API, scraper)
- ECS services
- Application Load Balancer
- Target groups
- Auto-scaling policies
- ECR repositories

**Outputs**:
- `ecs_cluster_name`
- `alb_dns_name`
- `alb_arn_suffix`
- `ecr_api_repository_url`
- `ecr_scraper_repository_url`

### monitoring
Sets up CloudWatch logs, metrics, alarms, and dashboards.

**Resources**:
- CloudWatch log groups
- CloudWatch alarms (CPU, memory, error rate, database)
- SNS topics for alerts
- CloudWatch dashboards
- Log retention policies

**Outputs**:
- `log_group_name`
- `sns_topic_arn`
- `dashboard_url`

## Module Development Guidelines

1. **Variables**: Use descriptive names and provide default values where appropriate
2. **Outputs**: Export all values that other modules might need
3. **Documentation**: Include a README.md with usage examples
4. **Validation**: Add variable validation rules where possible
5. **Tags**: Accept a `tags` variable and apply to all resources
6. **Naming**: Use consistent naming convention: `{app_name}-{environment}-{resource_type}`

## Usage Example

```hcl
module "networking" {
  source = "../../modules/networking"

  environment        = "dev"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  app_name          = "newscrape"

  tags = {
    Environment = "dev"
    Application = "newscrape"
  }
}
```

## Next Steps

To implement these modules, create the following files in each module directory:
1. `main.tf` - Resource definitions
2. `variables.tf` - Input variables with descriptions
3. `outputs.tf` - Output values
4. `README.md` - Module-specific documentation with examples
