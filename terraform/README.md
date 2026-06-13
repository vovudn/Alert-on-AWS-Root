# Terraform - Alert on AWS Root Login

Infrastructure as Code (IaC) implementation using Terraform for monitoring and alerting on AWS Root account logins.

## 📋 Prerequisites

### Required

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- AWS Account with Administrator permissions
- Email address for alerts

### Optional

- Phone number for SMS alerts
- [tfenv](https://github.com/tfutils/tfenv) for Terraform version management

## 🚀 Quick Start

### 1. Initialize Terraform

```bash
cd terraform

# Initialize Terraform (download providers)
terraform init
```

### 2. Configure Variables

Create `terraform.tfvars`:

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
# Windows
notepad terraform.tfvars

# Linux/Mac
nano terraform.tfvars
```

**Minimum configuration:**

```hcl
alert_email = "your-email@example.com"
```

**Full configuration:**

```hcl
aws_region  = "us-east-1"
alert_email = "security@example.com"
alert_phone = "+84123456789"

enable_lambda = false  # Set true to auto-disable root credentials
```

### 3. Plan and Deploy

```bash
# Preview changes
terraform plan

# Deploy infrastructure
terraform apply

# Approve when prompted
# Type: yes
```

### 4. Confirm Subscriptions

1. **Check email** for SNS confirmation
2. **Click confirmation link**
3. (If SMS enabled) **Reply YES** to SMS

### 5. Test (Optional)

Wait 5 minutes, then:

1. Log out of AWS Console
2. Log in with root account
3. Wait 5-10 minutes
4. Check email for alert

## 📁 Project Structure

```
terraform/
├── main.tf                    # Main infrastructure
├── lambda.tf                  # Lambda function (optional)
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example configuration
├── README.md                  # This file
└── .terraform/                # Terraform working directory (auto-generated)
```

## 🔧 Configuration Options

### Basic Configuration

```hcl
# Required
alert_email = "your-email@example.com"

# Optional
alert_phone        = "+84123456789"
aws_region         = "us-east-1"
environment        = "prod"
log_retention_days = 30
```

### Advanced Configuration

```hcl
# CloudTrail
cloudtrail_name        = "root-login-monitoring"
cloudtrail_bucket_name = "my-custom-bucket-name"

# CloudWatch
metric_namespace         = "Security"
alarm_evaluation_periods = 1
alarm_period_seconds     = 300
alarm_threshold          = 1

# Lambda (Auto-disable root credentials)
enable_lambda      = true
lambda_timeout     = 60
lambda_memory_size = 128
```

### Tagging

```hcl
additional_tags = {
  Team       = "Security"
  CostCenter = "IT-Ops"
  Compliance = "CIS-AWS"
  Owner      = "john.doe@example.com"
}
```

## 📊 Outputs

After deployment, Terraform displays:

```bash
Outputs:

account_id         = "123456789012"
region             = "us-east-1"
cloudtrail_name    = "root-login-monitoring"
alarm_name         = "RootAccountLoginAlarm"
sns_topic_arn      = "arn:aws:sns:..."
lambda_function_arn = "arn:aws:lambda:..." (if enabled)

# Console links
cloudwatch_logs_console = "https://..."
cloudtrail_console      = "https://..."
alarm_console           = "https://..."

# Next steps instructions
next_steps = "..."
```

View outputs anytime:

```bash
terraform output
terraform output sns_topic_arn
terraform output -json
```

## 🛠️ Common Operations

### View Current State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show aws_cloudwatch_metric_alarm.root_login
```

### Update Configuration

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Apply changes
terraform apply
```

### Enable Lambda Auto-Disable

```bash
# Edit terraform.tfvars
enable_lambda = true

# Apply
terraform apply
```

### Change Alert Email

```bash
# Edit terraform.tfvars
alert_email = "new-email@example.com"

# Apply
terraform apply

# Confirm new email subscription
```

### View CloudTrail Status

```bash
# Using AWS CLI
aws cloudtrail get-trail-status \
  --name $(terraform output -raw cloudtrail_name)

# View logs
aws logs tail $(terraform output -raw log_group_name) --follow
```

### View Alarm Status

```bash
aws cloudwatch describe-alarms \
  --alarm-names $(terraform output -raw alarm_name)
```

### Check Metrics

```bash
aws cloudwatch get-metric-statistics \
  --namespace $(terraform output -raw metric_namespace) \
  --metric-name RootAccountLoginCount \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

## 🧪 Testing

### Validate Configuration

```bash
# Check syntax
terraform validate

# Format code
terraform fmt

# Lint (requires tflint)
tflint
```

### Test Deployment

```bash
# Plan without applying
terraform plan -out=tfplan

# Review plan
terraform show tfplan

# Apply from plan
terraform apply tfplan
```

### Integration Test

```bash
# After deployment, trigger a test
# 1. Login with root account
# 2. Check alarm state
aws cloudwatch describe-alarms \
  --alarm-names $(terraform output -raw alarm_name) \
  --query 'MetricAlarms[0].StateValue'

# 3. Check recent events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=root \
  --max-results 5
```

## 🔐 Security Best Practices

### State File Security

**Important:** `terraform.tfstate` contains sensitive information!

#### Option 1: Local State (Development)

```bash
# Add to .gitignore
echo "terraform.tfstate*" >> .gitignore
echo "terraform.tfvars" >> .gitignore
echo ".terraform/" >> .gitignore
```

#### Option 2: Remote State (Production)

**S3 Backend:**

Create `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "root-login-alert/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Initialize:

```bash
terraform init -migrate-state
```

**Terraform Cloud:**

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "root-login-alert"
    }
  }
}
```

### Sensitive Variables

Use environment variables for sensitive data:

```bash
# Set environment variables
export TF_VAR_alert_email="security@example.com"
export TF_VAR_alert_phone="+84123456789"

# Deploy without terraform.tfvars
terraform apply
```

Or use AWS Secrets Manager:

```hcl
data "aws_secretsmanager_secret_version" "alert_email" {
  secret_id = "root-alert-email"
}

locals {
  alert_email = data.aws_secretsmanager_secret_version.alert_email.secret_string
}
```

## 🗑️ Cleanup

### Destroy All Resources

```bash
# Preview destruction
terraform plan -destroy

# Destroy all resources
terraform destroy

# Approve when prompted
# Type: yes
```

### Targeted Destroy

```bash
# Destroy specific resource
terraform destroy -target=aws_lambda_function.disable_root_credentials

# Destroy multiple resources
terraform destroy \
  -target=aws_lambda_function.disable_root_credentials \
  -target=aws_iam_role.lambda_execution
```

### Manual Cleanup

If `terraform destroy` fails:

```bash
# Delete S3 bucket contents first
aws s3 rm s3://$(terraform output -raw cloudtrail_bucket_name) --recursive

# Then destroy
terraform destroy
```

## 🐛 Troubleshooting

### Terraform Init Issues

```bash
# Clear cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

### Plan/Apply Fails

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify permissions
aws iam get-user

# Enable debug logging
TF_LOG=DEBUG terraform apply
```

### State Lock Issues

```bash
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Resource Already Exists

```bash
# Import existing resource
terraform import aws_s3_bucket.cloudtrail my-existing-bucket

# Or remove from state
terraform state rm aws_s3_bucket.cloudtrail
```

### Lambda Deployment Issues

```bash
# Check if zip file exists
ls -lh lambda_function.zip

# Manually create zip
cd ../lambda
zip ../terraform/lambda_function.zip lambda_function.py
cd ../terraform

# Re-apply
terraform apply
```

### SNS Subscription Not Confirmed

```bash
# List subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn $(terraform output -raw sns_topic_arn)

# Re-subscribe
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com
```

## 📈 Cost Estimation

### Using Terraform Cloud

```bash
# Enable cost estimation in Terraform Cloud
# Settings → Cost Estimation → Enable
```

### Using Infracost

```bash
# Install infracost
brew install infracost  # Mac
# or download from https://www.infracost.io/

# Generate cost breakdown
infracost breakdown --path .

# Compare before/after
terraform plan -out tfplan.binary
terraform show -json tfplan.binary > plan.json
infracost diff --path plan.json
```

### Manual Estimation

- CloudTrail: ~$2/month
- CloudWatch Logs: ~$0.50/month
- CloudWatch Metrics: ~$0.30/month
- SNS: ~$0.01/month + SMS costs
- Lambda: ~$0.00/month (minimal invocations)
- **Total: ~$3-5/month**

## 🔄 CI/CD Integration

### GitHub Actions

Create `.github/workflows/terraform.yml`:

```yaml
name: Terraform

on:
  push:
    branches: [main]
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Validate
        run: terraform validate
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./terraform
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          TF_VAR_alert_email: ${{ secrets.ALERT_EMAIL }}
```

### GitLab CI

Create `.gitlab-ci.yml`:

```yaml
image: hashicorp/terraform:latest

stages:
  - validate
  - plan
  - apply

validate:
  stage: validate
  script:
    - cd terraform
    - terraform init
    - terraform validate

plan:
  stage: plan
  script:
    - cd terraform
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - terraform/tfplan

apply:
  stage: apply
  script:
    - cd terraform
    - terraform init
    - terraform apply tfplan
  when: manual
  only:
    - main
```

## 📚 Additional Resources

### Terraform Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS CloudTrail Resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail)
- [AWS CloudWatch Alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)

### AWS Documentation

- [CloudTrail User Guide](https://docs.aws.amazon.com/cloudtrail/)
- [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
- [SNS Developer Guide](https://docs.aws.amazon.com/sns/)

### Project Documentation

- [Architecture](../docs/ARCHITECTURE.md)
- [Manual Setup](../docs/MANUAL-SETUP.md)
- [Testing Guide](../docs/TESTING.md)

## 🤝 Contributing

Contributions welcome! Please:

1. Test changes locally
2. Run `terraform fmt`
3. Run `terraform validate`
4. Update documentation
5. Submit pull request

## 📄 License

MIT License - See [LICENSE](../LICENSE)

## 📧 Support

- Issues: GitHub Issues
- Email: support@example.com
- Documentation: See `docs/` directory

---

**💡 Tip:** Use `terraform workspace` for managing multiple environments:

```bash
# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch workspace
terraform workspace select prod

# List workspaces
terraform workspace list
```
