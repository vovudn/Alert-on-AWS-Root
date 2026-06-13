# ============================================
# Variables for Root Login Alert
# ============================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "root-login-alert"
}

# ============================================
# Alert Configuration
# ============================================

variable "alert_email" {
  description = "Email address to receive alerts"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address."
  }
}

variable "alert_phone" {
  description = "Phone number for SMS alerts (format: +84123456789). Leave empty to disable SMS."
  type        = string
  default     = ""
  
  validation {
    condition     = var.alert_phone == "" || can(regex("^\\+[1-9]\\d{1,14}$", var.alert_phone))
    error_message = "Must be a valid phone number in E.164 format (e.g., +84123456789) or empty string."
  }
}

# ============================================
# CloudTrail Configuration
# ============================================

variable "cloudtrail_name" {
  description = "Name of the CloudTrail trail"
  type        = string
  default     = "root-login-monitoring"
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (leave empty to auto-generate)"
  type        = string
  default     = ""
}

# ============================================
# CloudWatch Configuration
# ============================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Must be a valid CloudWatch log retention value."
  }
}

variable "metric_namespace" {
  description = "CloudWatch metric namespace"
  type        = string
  default     = "Security"
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate the alarm"
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "Period in seconds for alarm evaluation"
  type        = number
  default     = 300
}

variable "alarm_threshold" {
  description = "Number of root logins to trigger alarm"
  type        = number
  default     = 1
}

# ============================================
# Lambda Configuration
# ============================================

variable "enable_lambda" {
  description = "Enable Lambda function to auto-disable root credentials"
  type        = bool
  default     = false
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
  
  validation {
    condition     = var.lambda_timeout >= 3 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 3 and 900 seconds."
  }
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory size must be between 128 and 10240 MB."
  }
}

# ============================================
# Tagging
# ============================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
