#------------------------------------------------------------------------------
# Security Module - Variables
#------------------------------------------------------------------------------
# Input variables for the security module.
#
# INDUSTRY CONTEXT:
# Security modules require careful variable design:
# - Sensible defaults that are secure by default
# - Validation to prevent misconfigurations
# - Clear documentation for security implications
# - Flexibility for different environments (dev vs prod)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) - used for resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid vpc-* identifier."
  }
}

#------------------------------------------------------------------------------
# Application Port Configuration
#------------------------------------------------------------------------------

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

#------------------------------------------------------------------------------
# Database Port Configuration
#------------------------------------------------------------------------------

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432

  validation {
    condition     = var.db_port > 0 && var.db_port <= 65535
    error_message = "Database port must be between 1 and 65535."
  }
}

#------------------------------------------------------------------------------
# SSM Session Manager Configuration
#------------------------------------------------------------------------------

variable "enable_ssm_access" {
  description = "Enable SSM Session Manager access to EC2 instances"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Bastion Host Configuration
#------------------------------------------------------------------------------

variable "create_bastion_sg" {
  description = "Create security group for bastion host (SSH access)"
  type        = bool
  default     = false
}

variable "bastion_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.bastion_allowed_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All bastion allowed CIDRs must be valid CIDR blocks."
  }
}

#------------------------------------------------------------------------------
# S3 Access Configuration
#------------------------------------------------------------------------------

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that EC2 instances can read from"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.s3_bucket_arns : can(regex("^arn:aws:s3:::", arn))
    ])
    error_message = "All S3 bucket ARNs must be valid ARN format (arn:aws:s3:::bucket-name)."
  }
}

#------------------------------------------------------------------------------
# Additional Security Group Rules
#------------------------------------------------------------------------------

variable "additional_app_ingress_rules" {
  description = "Additional ingress rules for app security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "additional_app_egress_rules" {
  description = "Additional egress rules for app security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

#------------------------------------------------------------------------------
# Tagging
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Advanced IAM Configuration
#------------------------------------------------------------------------------

variable "iam_permissions_boundary" {
  description = "ARN of IAM permissions boundary to apply to roles"
  type        = string
  default     = null
}

variable "additional_iam_policies" {
  description = "List of additional IAM policy ARNs to attach to EC2 role"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.additional_iam_policies : can(regex("^arn:aws:iam::", arn))
    ])
    error_message = "All IAM policy ARNs must be valid ARN format."
  }
}