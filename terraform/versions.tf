# ============================================
# Terraform and Provider Version Constraints
# ============================================

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  
  # Optional: Configure backend for remote state
  # Uncomment and configure for production use
  
  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket"
  #   key            = "root-login-alert/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
