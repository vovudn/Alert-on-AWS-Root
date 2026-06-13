# ============================================
# Alert on AWS Root Account Login - Terraform
# ============================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "RootLoginAlert"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Get current AWS account info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================
# S3 Bucket for CloudTrail
# ============================================

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = var.cloudtrail_bucket_name != "" ? var.cloudtrail_bucket_name : "${var.project_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"
  force_destroy = true  # Allow Terraform to delete bucket even with objects
  
  tags = {
    Name    = "CloudTrail Logs"
    Purpose = "Security Monitoring"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  rule {
    id     = "DeleteOldLogs"
    status = "Enabled"
    
    filter {}  # Apply to all objects
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}


# ============================================
# CloudWatch Log Group
# ============================================

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/root-login-monitoring"
  retention_in_days = var.log_retention_days
  
  tags = {
    Name    = "CloudTrail Logs"
    Purpose = "Security Monitoring"
  }
}

# ============================================
# IAM Role for CloudTrail to CloudWatch Logs
# ============================================

resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "${var.project_name}-CloudTrailToCloudWatchLogs"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name = "CloudTrail to CloudWatch Logs Role"
  }
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch" {
  name = "CloudWatchLogsPolicy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# ============================================
# CloudTrail
# ============================================

resource "aws_cloudtrail" "root_login_monitoring" {
  name                          = var.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
  
  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_to_cloudwatch
  ]
  
  tags = {
    Name    = "Root Login Monitoring Trail"
    Purpose = "Security Monitoring"
  }
}

# ============================================
# CloudWatch Metric Filter
# ============================================

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "RootAccountLoginCount"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  
  metric_transformation {
    name          = "RootAccountLoginCount"
    namespace     = var.metric_namespace
    value         = "1"
    default_value = "0"
  }
}

# ============================================
# SNS Topic
# ============================================

resource "aws_sns_topic" "root_login_alerts" {
  name         = "${var.project_name}-alerts"
  display_name = "AWS Root Account Login Alert"
  
  tags = {
    Name    = "Root Login Alert Topic"
    Purpose = "Security Alerts"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.root_login_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "sms" {
  count     = var.alert_phone != "" ? 1 : 0
  topic_arn = aws_sns_topic.root_login_alerts.arn
  protocol  = "sms"
  endpoint  = var.alert_phone
}

# ============================================
# CloudWatch Alarm
# ============================================

resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "RootAccountLoginAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "RootAccountLoginCount"
  namespace           = var.metric_namespace
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "SECURITY ALERT: Root account login detected! Any single root login should trigger this alarm. Investigate immediately and verify if this was authorized."
  treat_missing_data  = "notBreaching"
  
  alarm_actions = concat(
    [aws_sns_topic.root_login_alerts.arn],
    var.enable_lambda ? [aws_lambda_function.disable_root_credentials[0].arn] : []
  )
  
  tags = {
    Name     = "Root Login Alarm"
    Severity = "Critical"
  }
}
