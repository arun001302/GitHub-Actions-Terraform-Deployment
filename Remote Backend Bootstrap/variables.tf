#------------------------------------------------------------------------------
# Bootstrap Variables
#------------------------------------------------------------------------------
# Input variables for the bootstrap configuration.
#
# INDUSTRY CONTEXT:
# Well-designed variables include:
# - Descriptions (documentation is code)
# - Type constraints (catch errors early)
# - Validation rules (prevent invalid configurations)
# - Sensible defaults (reduce friction for common cases)
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where the state backend will be created"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "project_name" {
  description = "Name of the project - used for resource naming and tagging"
  type        = string
  default     = "iac-pipeline"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment identifier for the state backend"
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["shared", "management"], var.environment)
    error_message = "Environment must be 'shared' or 'management' for bootstrap resources."
  }
}

#------------------------------------------------------------------------------
# S3 Bucket Configuration
#------------------------------------------------------------------------------

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "S3 bucket name must be 3-63 characters, lowercase, and DNS-compliant."
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the state bucket (strongly recommended)"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption on the state bucket"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# DynamoDB Configuration
#------------------------------------------------------------------------------

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
  default     = null # Will default to "{project_name}-terraform-locks" if not specified
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode - PAY_PER_REQUEST recommended for state locking"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "DynamoDB billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}