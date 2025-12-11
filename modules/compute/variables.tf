#------------------------------------------------------------------------------
# Compute Module - Variables
#------------------------------------------------------------------------------
# Input variables for the compute module.
#
# INDUSTRY CONTEXT:
# Compute variables are designed with these principles:
# - Sensible defaults for dev environments (small, cheap)
# - Easy to scale up for production via tfvars
# - Security-first defaults (encrypted, IMDSv2, no public IP)
# - Flexibility for different application requirements
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

variable "subnet_ids" {
  description = "List of subnet IDs where instances will be launched"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "security_group_id" {
  description = "Security group ID to attach to instances"
  type        = string

  validation {
    condition     = can(regex("^sg-[a-z0-9]+$", var.security_group_id))
    error_message = "Security group ID must be a valid sg-* identifier."
  }
}

variable "instance_profile_name" {
  description = "IAM instance profile name to attach to instances"
  type        = string
}

#------------------------------------------------------------------------------
# Instance Configuration
#------------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid format (e.g., t3.micro, m5.large)."
  }
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_architecture" {
  description = "CPU architecture: x86_64 (Intel/AMD) or arm64 (Graviton)"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.instance_architecture)
    error_message = "Architecture must be x86_64 or arm64."
  }
}

#------------------------------------------------------------------------------
# Storage Configuration
#------------------------------------------------------------------------------

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "root_volume_iops" {
  description = "IOPS for root EBS volume (GP3: 3000-16000)"
  type        = number
  default     = 3000

  validation {
    condition     = var.root_volume_iops >= 3000 && var.root_volume_iops <= 16000
    error_message = "Root volume IOPS must be between 3000 and 16000 for GP3."
  }
}

variable "root_volume_throughput" {
  description = "Throughput for root EBS volume in MB/s (GP3: 125-1000)"
  type        = number
  default     = 125

  validation {
    condition     = var.root_volume_throughput >= 125 && var.root_volume_throughput <= 1000
    error_message = "Root volume throughput must be between 125 and 1000 MB/s for GP3."
  }
}

#------------------------------------------------------------------------------
# Network Configuration
#------------------------------------------------------------------------------

variable "associate_public_ip" {
  description = "Associate public IP address with instances"
  type        = bool
  default     = false
}

variable "create_elastic_ip" {
  description = "Create and attach Elastic IP to instances"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# User Data Configuration
#------------------------------------------------------------------------------

variable "user_data" {
  description = "User data script to run on instance launch (leave empty for default)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Monitoring Configuration
#------------------------------------------------------------------------------

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (1-minute intervals)"
  type        = bool
  default     = true
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for instance monitoring"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for CloudWatch alarm (%)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_alarm_threshold > 0 && var.cpu_alarm_threshold <= 100
    error_message = "CPU alarm threshold must be between 1 and 100."
  }
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers (e.g., SNS topic ARNs)"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Security Configuration
#------------------------------------------------------------------------------

variable "enable_termination_protection" {
  description = "Enable termination protection (prevents accidental deletion)"
  type        = bool
  default     = false
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
# Advanced Configuration
#------------------------------------------------------------------------------

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to instances"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Name of SSH key pair (not recommended - use SSM instead)"
  type        = string
  default     = null
}

variable "placement_group" {
  description = "Name of placement group for instances"
  type        = string
  default     = null
}

variable "tenancy" {
  description = "Instance tenancy: default, dedicated, or host"
  type        = string
  default     = "default"

  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "Tenancy must be default, dedicated, or host."
  }
}