#------------------------------------------------------------------------------
# Bootstrap Outputs
#------------------------------------------------------------------------------
# These outputs provide the values needed to configure the backend
# in your main Terraform configuration.
#
# INDUSTRY CONTEXT:
# Outputs serve multiple purposes:
# 1. Display values after apply (human readable)
# 2. Enable programmatic access to resource attributes
# 3. Pass values between Terraform configurations (state data sources)
# 4. Document what "this module produces"
#
# After running `terraform apply` on bootstrap, you'll copy these values
# into your main configuration's backend.tf file.
#------------------------------------------------------------------------------

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_bucket_region" {
  description = "Region where the state bucket was created"
  value       = aws_s3_bucket.terraform_state.region
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.arn
}

#------------------------------------------------------------------------------
# Backend Configuration Block (Copy-Paste Ready)
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# This output generates the exact backend configuration block you need.
# It's a convenience that reduces copy-paste errors - a common source
# of "why isn't my state working" debugging sessions.
#------------------------------------------------------------------------------

output "backend_config" {
  description = "Backend configuration block for main Terraform configuration"
  value       = <<-EOT
    #--------------------------------------------------------------------------
    # Copy this block to your main configuration's backend.tf
    #--------------------------------------------------------------------------
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "terraform.tfstate"
        region         = "${aws_s3_bucket.terraform_state.region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }
  EOT
}

#------------------------------------------------------------------------------
# GitHub Actions Backend Config (for CI/CD pipeline)
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# CI/CD pipelines often need backend values as environment variables
# or workflow inputs. This output formats the values for easy integration.
#------------------------------------------------------------------------------

output "github_actions_env_vars" {
  description = "Environment variables for GitHub Actions workflow"
  value       = <<-EOT
    # Add these to your GitHub repository secrets or workflow env
    TF_BACKEND_BUCKET=${aws_s3_bucket.terraform_state.id}
    TF_BACKEND_REGION=${aws_s3_bucket.terraform_state.region}
    TF_BACKEND_DYNAMODB_TABLE=${aws_dynamodb_table.terraform_locks.name}
  EOT
}