#------------------------------------------------------------------------------
# Networking Module - Variables
#------------------------------------------------------------------------------
# Input variables for the networking module.
#
# INDUSTRY CONTEXT:
# Well-designed module variables follow these principles:
# 1. Required variables have no defaults (force explicit configuration)
# 2. Optional variables have sensible defaults
# 3. Validation rules catch errors before apply
# 4. Descriptions serve as documentation
# 5. Type constraints prevent misconfigurations
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------
# These MUST be provided when calling the module - no defaults.
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) - used for resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "VPC CIDR should be /16 or larger to accommodate multiple subnets."
  }
}

#------------------------------------------------------------------------------
# Availability Zone Configuration
#------------------------------------------------------------------------------

variable "az_count" {
  description = "Number of Availability Zones to use (minimum 2 for high availability)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "AZ count must be between 2 and 6."
  }
}

#------------------------------------------------------------------------------
# NAT Gateway Configuration
#------------------------------------------------------------------------------
# NAT Gateway enables outbound internet for private subnets.
#
# INDUSTRY CONTEXT:
# Cost consideration is important here:
# - NAT Gateway: ~$32/month + data transfer
# - For dev/test: often disabled to save costs
# - For staging: single NAT is acceptable
# - For production: multi-AZ NAT recommended (one per AZ)
#
# This module implements single NAT for simplicity. For production multi-AZ,
# you would modify to create one NAT per AZ with separate route tables.
#------------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# VPC Flow Logs Configuration
#------------------------------------------------------------------------------
# Flow logs capture network traffic metadata for security and troubleshooting.
#
# INDUSTRY CONTEXT:
# - Required for most compliance frameworks (PCI-DSS, HIPAA, SOC2)
# - Essential for security incident investigation
# - Adds cost (CloudWatch Logs storage) - ~$0.50/GB ingested
# - For dev environments, often disabled to save costs
#------------------------------------------------------------------------------

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs for network traffic monitoring"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain flow logs in CloudWatch"
  type        = number
  default     = 14

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.flow_logs_retention_days)
    error_message = "Flow logs retention must be a valid CloudWatch Logs retention period."
  }
}

#------------------------------------------------------------------------------
# Tagging
#------------------------------------------------------------------------------
# Tags are critical for cost allocation, automation, and organization.
#
# INDUSTRY CONTEXT:
# Common required tags in enterprises:
# - Environment: dev/staging/prod
# - Project/Application: for cost allocation
# - Owner/Team: for accountability
# - CostCenter: for chargeback
# - ManagedBy: terraform (for automation identification)
#------------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Advanced Configuration (Optional)
#------------------------------------------------------------------------------
# These variables provide fine-grained control for specific use cases.
# Most users can ignore these and use defaults.
#------------------------------------------------------------------------------

variable "create_database_subnets" {
  description = "Create dedicated database subnets (separate from private subnets)"
  type        = bool
  default     = false
}

variable "database_subnet_suffix" {
  description = "Suffix to append to database subnet names"
  type        = string
  default     = "db"
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnet names"
  type        = string
  default     = "public"
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnet names"
  type        = string
  default     = "private"
}