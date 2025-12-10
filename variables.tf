#------------------------------------------------------------------------------
# Root Module - Variables
#------------------------------------------------------------------------------
# These variables are the "interface" for the entire infrastructure.
# Values are provided via environments/*.tfvars files.
#
# INDUSTRY CONTEXT:
# Root variables aggregate all configurable options. They:
# - Provide a single place to see all configuration options
# - Are populated by environment-specific .tfvars files
# - Pass values down to child modules
#
# Naming convention: Module-specific vars are prefixed (db_, etc.)
# to avoid confusion and enable easy searching.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# General Configuration
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "iac-pipeline"
}

#------------------------------------------------------------------------------
# Networking Variables
#------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "AZ count must be between 2 and 6."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Days to retain VPC Flow Logs"
  type        = number
  default     = 14
}

#------------------------------------------------------------------------------
# Security Variables
#------------------------------------------------------------------------------

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 5432
}

variable "enable_ssm_access" {
  description = "Enable SSM Session Manager access to EC2 instances"
  type        = bool
  default     = true
}

variable "create_bastion_sg" {
  description = "Create security group for bastion host"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Compute Variables
#------------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_architecture" {
  description = "CPU architecture: x86_64 or arm64 (Graviton)"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.instance_architecture)
    error_message = "Architecture must be x86_64 or arm64."
  }
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_iops" {
  description = "IOPS for root EBS volume (GP3)"
  type        = number
  default     = 3000
}

variable "root_volume_throughput" {
  description = "Throughput for root EBS volume in MB/s (GP3)"
  type        = number
  default     = 125
}

variable "associate_public_ip" {
  description = "Associate public IP address with instances"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for EC2 instances"
  type        = bool
  default     = false
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "enable_termination_protection" {
  description = "Enable EC2 termination protection"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Database Variables
#------------------------------------------------------------------------------

variable "db_engine" {
  description = "Database engine (postgres, mysql, mariadb)"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.db_engine)
    error_message = "Database engine must be postgres, mysql, or mariadb."
  }
}

variable "db_engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_storage_iops" {
  description = "Provisioned IOPS for GP3 storage"
  type        = number
  default     = 3000
}

variable "db_storage_throughput" {
  description = "Storage throughput in MB/s for GP3"
  type        = number
  default     = 125
}

variable "db_name" {
  description = "Name of the default database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "db_enable_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying RDS"
  type        = bool
  default     = true
}

variable "db_enable_performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_performance_insights_retention" {
  description = "Days to retain Performance Insights data"
  type        = number
  default     = 7
}

variable "db_monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 0
}

variable "db_create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for RDS"
  type        = bool
  default     = false
}

variable "db_cpu_alarm_threshold" {
  description = "RDS CPU utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "db_free_storage_alarm_threshold" {
  description = "RDS free storage space threshold for alarm (GB)"
  type        = number
  default     = 5
}

variable "db_freeable_memory_alarm_threshold" {
  description = "RDS freeable memory threshold for alarm (MB)"
  type        = number
  default     = 256
}

variable "db_max_connections_alarm_threshold" {
  description = "RDS maximum connections threshold for alarm"
  type        = number
  default     = 100
}

variable "db_backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}