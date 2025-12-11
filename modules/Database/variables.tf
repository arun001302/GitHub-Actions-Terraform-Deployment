#------------------------------------------------------------------------------
# Database Module - Variables
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (minimum 2 AZs)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

#------------------------------------------------------------------------------
# Engine Configuration
#------------------------------------------------------------------------------

variable "engine" {
  description = "Database engine: postgres, mysql, or mariadb"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "15"
}

variable "parameter_group_family" {
  description = "DB parameter group family (auto-detected if null)"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Instance Configuration
#------------------------------------------------------------------------------

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

#------------------------------------------------------------------------------
# Storage Configuration
#------------------------------------------------------------------------------

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB (0 to disable)"
  type        = number
  default     = 100
}

variable "storage_iops" {
  description = "Provisioned IOPS for GP3 storage"
  type        = number
  default     = 3000
}

variable "storage_throughput" {
  description = "Storage throughput in MB/s for GP3"
  type        = number
  default     = 125
}

#------------------------------------------------------------------------------
# Database Configuration
#------------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
}

variable "db_port" {
  description = "Port for the database"
  type        = number
  default     = null
}

#------------------------------------------------------------------------------
# High Availability Configuration
#------------------------------------------------------------------------------

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Backup Configuration
#------------------------------------------------------------------------------

variable "backup_retention_period" {
  description = "Days to retain automated backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

#------------------------------------------------------------------------------
# Monitoring Configuration
#------------------------------------------------------------------------------

variable "enable_performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention" {
  description = "Days to retain Performance Insights data"
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds"
  type        = number
  default     = 60
}

variable "cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql"]
}

variable "enable_query_logging" {
  description = "Enable query logging"
  type        = bool
  default     = false
}

variable "slow_query_log_threshold" {
  description = "Threshold for slow query logging in milliseconds"
  type        = number
  default     = 1000
}

#------------------------------------------------------------------------------
# CloudWatch Alarm Configuration
#------------------------------------------------------------------------------

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 80
}

variable "free_storage_alarm_threshold" {
  description = "Free storage space threshold for alarm (GB)"
  type        = number
  default     = 5
}

variable "freeable_memory_alarm_threshold" {
  description = "Freeable memory threshold for alarm (MB)"
  type        = number
  default     = 256
}

variable "max_connections_alarm_threshold" {
  description = "Maximum database connections threshold"
  type        = number
  default     = 100
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Security Configuration
#------------------------------------------------------------------------------

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "secret_recovery_window_days" {
  description = "Days before secret is permanently deleted"
  type        = number
  default     = 7
}

#------------------------------------------------------------------------------
# Operational Configuration
#------------------------------------------------------------------------------

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
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