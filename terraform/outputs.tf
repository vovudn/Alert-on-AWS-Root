# ============================================
# Outputs for Root Login Alert
# ============================================

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

# ============================================
# CloudTrail Outputs
# ============================================

output "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  value       = aws_cloudtrail.root_login_monitoring.name
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.root_login_monitoring.arn
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket name storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.cloudtrail.arn
}

# ============================================
# CloudWatch Outputs
# ============================================

output "log_group_name" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "metric_filter_name" {
  description = "Name of the CloudWatch Metric Filter"
  value       = aws_cloudwatch_log_metric_filter.root_login.name
}

output "metric_namespace" {
  description = "CloudWatch metric namespace"
  value       = var.metric_namespace
}

output "metric_name" {
  description = "CloudWatch metric name"
  value       = "RootAccountLoginCount"
}

# ============================================
# Alarm Outputs
# ============================================

output "alarm_name" {
  description = "Name of the CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.root_login.alarm_name
}

output "alarm_arn" {
  description = "ARN of the CloudWatch Alarm"
  value       = aws_cloudwatch_metric_alarm.root_login.arn
}

# ============================================
# SNS Outputs
# ============================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.root_login_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.root_login_alerts.name
}

output "alert_email" {
  description = "Email address receiving alerts"
  value       = var.alert_email
}

output "alert_phone" {
  description = "Phone number receiving SMS alerts"
  value       = var.alert_phone != "" ? var.alert_phone : "Not configured"
}

# ============================================
# Lambda Outputs (if enabled)
# ============================================

output "lambda_function_name" {
  description = "Name of the Lambda function (if enabled)"
  value       = var.enable_lambda ? aws_lambda_function.disable_root_credentials[0].function_name : "Not enabled"
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function (if enabled)"
  value       = var.enable_lambda ? aws_lambda_function.disable_root_credentials[0].arn : "Not enabled"
}

output "lambda_log_group" {
  description = "CloudWatch Log Group for Lambda (if enabled)"
  value       = var.enable_lambda ? aws_cloudwatch_log_group.lambda[0].name : "Not enabled"
}

# ============================================
# Console Links
# ============================================

output "cloudwatch_logs_console" {
  description = "Link to CloudWatch Logs console"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.cloudtrail.name, "/", "$252F")}"
}

output "cloudtrail_console" {
  description = "Link to CloudTrail console"
  value       = "https://console.aws.amazon.com/cloudtrail/home?region=${data.aws_region.current.name}#/trails/${aws_cloudtrail.root_login_monitoring.name}"
}

output "alarm_console" {
  description = "Link to CloudWatch Alarms console"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#alarmsV2:alarm/${aws_cloudwatch_metric_alarm.root_login.alarm_name}"
}

output "sns_console" {
  description = "Link to SNS Topics console"
  value       = "https://console.aws.amazon.com/sns/v3/home?region=${data.aws_region.current.name}#/topic/${aws_sns_topic.root_login_alerts.arn}"
}

# ============================================
# Next Steps
# ============================================

output "next_steps" {
  description = "Instructions for completing setup"
  value       = <<-EOT
    ========================================
    Deployment Complete! Next Steps:
    ========================================
    
    1. ✉️  CHECK YOUR EMAIL (${var.alert_email})
       - Look for AWS SNS confirmation email
       - Click the "Confirm subscription" link
       - Check spam folder if not found
    
    ${var.alert_phone != "" ? "2. 📱 CHECK YOUR SMS (${var.alert_phone})\n       - Reply 'YES' to confirm subscription\n    \n    " : ""}
    ${var.alert_phone != "" ? "3" : "2"}. ⏱️  WAIT 5 MINUTES
       - Allow CloudTrail to start logging
       - Allow services to initialize
    
    ${var.alert_phone != "" ? "4" : "3"}. ✅ TEST THE SYSTEM (Optional)
       - Log out of AWS Console
       - Log in using root account
       - Wait 5-10 minutes
       - Check for alert email/SMS
    
    ${var.alert_phone != "" ? "5" : "4"}. 📊 MONITOR
       - CloudWatch Logs: ${aws_cloudwatch_log_group.cloudtrail.name}
       - CloudWatch Alarm: ${aws_cloudwatch_metric_alarm.root_login.alarm_name}
       - Metric: ${var.metric_namespace}/RootAccountLoginCount
    
    ========================================
    Quick Commands:
    ========================================
    
    # View alarm status
    aws cloudwatch describe-alarms --alarm-names ${aws_cloudwatch_metric_alarm.root_login.alarm_name}
    
    # View metrics
    aws cloudwatch get-metric-statistics \
      --namespace ${var.metric_namespace} \
      --metric-name RootAccountLoginCount \
      --start-time $(date -u -d '1 hour ago' +%%Y-%%m-%%dT%%H:%%M:%%S) \
      --end-time $(date -u +%%Y-%%m-%%dT%%H:%%M:%%S) \
      --period 300 \
      --statistics Sum
    
    # View CloudTrail status
    aws cloudtrail get-trail-status --name ${aws_cloudtrail.root_login_monitoring.name}
    
    ========================================
    ${var.enable_lambda ? "⚠️  Lambda Auto-Disable Enabled\nRoot access keys will be automatically disabled on login detection.\n    ========================================\n    " : ""}
    Documentation: See terraform/README.md
    ========================================
  EOT
}
