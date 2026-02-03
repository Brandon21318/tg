# newsScrape Infrastructure & Deployment

This repository manages the infrastructure and deployment for the newsScrape_go application using Infrastructure as Code (IaC) and deployment automation.

## Repository Structure

```
tg/
├── terraform/              # Infrastructure as Code
│   ├── environments/       # Environment-specific configurations
│   │   ├── dev/           # Development environment
│   │   ├── staging/       # Staging environment
│   │   └── production/    # Production environment
│   └── modules/           # Reusable Terraform modules
│       ├── networking/    # VPC, subnets, security groups
│       ├── compute/       # EC2, ECS, load balancers
│       ├── database/      # RDS PostgreSQL
│       ├── monitoring/    # CloudWatch, alarms
│       └── security/      # IAM roles, secrets
├── deploy/                # Deployment automation
│   ├── ansible/          # Ansible playbooks
│   └── docker/           # Docker configurations
├── scripts/              # Utility scripts
└── docs/                 # Documentation
```

## Prerequisites

### Required Tools
- **Terraform** >= 1.5.0 or **OpenTofu** >= 1.6.0
- **AWS CLI** >= 2.0
- **Docker** >= 24.0
- **Ansible** >= 2.15 (optional, for configuration management)

### AWS Configuration
```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

## Quick Start

### 1. Clone the repository
```bash
git clone git@github.com:Brandon21318/tg.git
cd tg
```

### 2. Initialize Terraform
```bash
cd terraform/environments/dev
terraform init
```

### 3. Plan infrastructure changes
```bash
terraform plan
```

### 4. Apply infrastructure
```bash
terraform apply
```

## Infrastructure Components

### Networking
- **VPC**: Isolated network for the application
- **Subnets**: Public and private subnets across multiple AZs
- **Security Groups**: Firewall rules for resources
- **NAT Gateway**: Outbound internet access for private subnets

### Compute
- **ECS Cluster**: Container orchestration
- **ECS Services**: API and scraper services
- **Application Load Balancer**: Traffic distribution and SSL termination
- **Auto Scaling**: Dynamic scaling based on load

### Database
- **RDS PostgreSQL**: Managed database service
- **Read Replicas**: For scaling read operations (production only)
- **Automated Backups**: Point-in-time recovery
- **Multi-AZ**: High availability (staging/production)

### Security
- **IAM Roles**: Least-privilege access for services
- **Secrets Manager**: Secure credential storage
- **ACM**: SSL/TLS certificates
- **WAF**: Web Application Firewall (production only)

### Monitoring
- **CloudWatch Logs**: Centralized logging
- **CloudWatch Alarms**: Resource and application monitoring
- **SNS Topics**: Alert notifications
- **CloudWatch Dashboards**: Metrics visualization

## Environments

### Development
- **Purpose**: Local development and testing
- **Resources**: Minimal (t3.micro, single AZ)
- **Cost**: ~$50-100/month
- **Data**: Test data only

### Staging
- **Purpose**: Pre-production testing
- **Resources**: Medium (t3.small, multi-AZ)
- **Cost**: ~$200-300/month
- **Data**: Production snapshot with anonymized data

### Production
- **Purpose**: Live application
- **Resources**: Production-grade (t3.medium+, multi-AZ, auto-scaling)
- **Cost**: ~$500-800/month
- **Data**: Real user data

## Deployment Workflow

### Infrastructure Changes
1. Create feature branch: `git checkout -b infra/feature-name`
2. Make changes in appropriate environment
3. Run `terraform plan` to preview changes
4. Create pull request for review
5. After approval, merge to main
6. Run `terraform apply` in target environment

### Application Deployment
1. Application updates pushed to `newsScrape_go` repository
2. CI/CD pipeline builds Docker images
3. Images pushed to ECR (Elastic Container Registry)
4. ECS services updated with new images
5. Rolling deployment with health checks

## State Management

Terraform state is stored remotely in S3 with state locking via DynamoDB.

**Backend Configuration** (created during initial setup):
- **S3 Bucket**: `newscrape-terraform-state-{account-id}`
- **DynamoDB Table**: `newscrape-terraform-locks`
- **Encryption**: AES256
- **Versioning**: Enabled

## Security Best Practices

- [ ] Never commit secrets to git
- [ ] Use AWS Secrets Manager for sensitive data
- [ ] Enable MFA for AWS root account
- [ ] Use IAM roles instead of access keys where possible
- [ ] Regularly rotate credentials
- [ ] Enable CloudTrail for audit logging
- [ ] Use VPC endpoints for AWS services
- [ ] Implement least-privilege IAM policies

## Cost Optimization

- **Development**: Shut down non-critical resources after hours
- **Staging**: Use reserved instances for predictable workloads
- **Production**:
  - Use Savings Plans for compute
  - Enable RDS auto-scaling for read replicas
  - Implement lifecycle policies for old logs and backups

## Disaster Recovery

- **RTO** (Recovery Time Objective): 1 hour
- **RPO** (Recovery Point Objective): 5 minutes
- **Backup Strategy**:
  - Daily automated RDS snapshots (retained 7 days)
  - Weekly manual snapshots (retained 30 days)
  - Cross-region replication for critical data

## Monitoring & Alerts

### Key Metrics
- API response time (p95, p99)
- Error rate (4xx, 5xx)
- Database connections
- CPU/Memory utilization
- Disk space

### Alert Thresholds
- **Critical**: Page on-call engineer
  - API error rate > 5%
  - Database CPU > 90%
  - Disk space < 10%
- **Warning**: Email notification
  - API response time p95 > 500ms
  - Memory utilization > 80%

## Troubleshooting

### Common Issues

**Issue**: Terraform state lock error
```bash
# Solution: Force unlock (use with caution)
terraform force-unlock <lock-id>
```

**Issue**: ECS service fails to stabilize
```bash
# Check service events
aws ecs describe-services --cluster newscrape --service api-service

# Check task logs
aws logs tail /ecs/newscrape/api --follow
```

**Issue**: Database connection timeout
```bash
# Verify security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id>

# Test connectivity from ECS task
aws ecs execute-command --cluster newscrape --task <task-id> --interactive --command "nc -zv database-endpoint 5432"
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Terraform Modules](docs/terraform-modules.md)
- [Deployment Guide](docs/deployment.md)
- [Runbook](docs/runbook.md)

## Contributing

1. Create feature branch from `main`
2. Make changes and test locally
3. Run `terraform fmt` to format code
4. Run `terraform validate` to check syntax
5. Create pull request with description
6. After review and approval, merge to `main`

## Support

For infrastructure issues:
- Create an issue in this repository
- Tag with appropriate environment label (dev/staging/production)

## License

MIT License - see LICENSE file for details

## Related Repositories

- [newsScrape_go](https://github.com/Brandon21318/newsScrape_go) - Application code
