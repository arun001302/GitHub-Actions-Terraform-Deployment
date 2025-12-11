#------------------------------------------------------------------------------
# Production Environment Configuration
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# General
#------------------------------------------------------------------------------

environment  = "prod"
aws_region   = "us-east-1"
project_name = "iac-pipeline"

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------

vpc_cidr                 = "10.2.0.0/16"
az_count                 = 3
enable_nat_gateway       = true
enable_flow_logs         = true
flow_logs_retention_days = 90

#------------------------------------------------------------------------------
# Security
#------------------------------------------------------------------------------

app_port          = 8080
db_port           = 5432
enable_ssm_access = true
create_bastion_sg = false

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------

instance_type         = "t3.medium"
instance_count        = 2
instance_architecture = "x86_64"

root_volume_size       = 50
root_volume_iops       = 3000
root_volume_throughput = 125

associate_public_ip           = false
enable_detailed_monitoring    = true
create_cloudwatch_alarms      = true
cpu_alarm_threshold           = 70
enable_termination_protection = true

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

db_engine         = "postgres"
db_engine_version = "15"
db_instance_class = "db.t3.medium"

db_allocated_storage     = 100
db_max_allocated_storage = 500
db_storage_iops          = 3000
db_storage_throughput    = 125

db_name     = "appdb"
db_username = "dbadmin"

db_multi_az                   = true
db_backup_retention_period    = 35
db_enable_deletion_protection = true
db_skip_final_snapshot        = false

db_enable_performance_insights    = true
db_performance_insights_retention = 731
db_monitoring_interval            = 30

db_create_cloudwatch_alarms        = true
db_cpu_alarm_threshold             = 70
db_free_storage_alarm_threshold    = 20
db_freeable_memory_alarm_threshold = 512
db_max_connections_alarm_threshold = 80

db_backup_window      = "03:00-04:00"
db_maintenance_window = "sun:04:00-sun:05:00"

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

tags = {
  Environment        = "prod"
  Project            = "iac-pipeline"
  ManagedBy          = "terraform"
  CostCenter         = "production"
  DataClassification = "confidential"
  Compliance         = "required"
  BackupPolicy       = "daily"
  MaintenanceWindow  = "sunday-0400-utc"
}