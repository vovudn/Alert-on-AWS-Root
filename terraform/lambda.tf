# ============================================
# Lambda Function (Optional)
# ============================================

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution" {
  count = var.enable_lambda ? 1 : 0
  name  = "${var.project_name}-LambdaExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name = "Lambda Execution Role"
  }
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count      = var.enable_lambda ? 1 : 0
  role       = aws_iam_role.lambda_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda
resource "aws_iam_role_policy" "lambda_custom" {
  count = var.enable_lambda ? 1 : 0
  name  = "RootAccountMonitoring"
  role  = aws_iam_role.lambda_execution[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListAccessKeys",
          "iam:UpdateAccessKey",
          "iam:DeleteAccessKey",
          "cloudtrail:LookupEvents",
          "sns:Publish",
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create zip file for Lambda function
data "archive_file" "lambda_zip" {
  count       = var.enable_lambda ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/../lambda/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Function
resource "aws_lambda_function" "disable_root_credentials" {
  count         = var.enable_lambda ? 1 : 0
  filename      = data.archive_file.lambda_zip[0].output_path
  function_name = "disable-root-credentials"
  role          = aws_iam_role.lambda_execution[0].arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.root_login_alerts.arn
    }
  }
  
  tags = {
    Name    = "Disable Root Credentials"
    Purpose = "Security Automation"
  }
}

# Lambda permission for SNS to invoke
resource "aws_lambda_permission" "allow_sns" {
  count         = var.enable_lambda ? 1 : 0
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disable_root_credentials[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.root_login_alerts.arn
}

# SNS subscription for Lambda
resource "aws_sns_topic_subscription" "lambda" {
  count     = var.enable_lambda ? 1 : 0
  topic_arn = aws_sns_topic.root_login_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.disable_root_credentials[0].arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  count             = var.enable_lambda ? 1 : 0
  name              = "/aws/lambda/disable-root-credentials"
  retention_in_days = 7
  
  tags = {
    Name = "Lambda Logs"
  }
}
