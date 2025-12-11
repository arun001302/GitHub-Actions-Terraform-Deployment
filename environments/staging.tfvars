#------------------------------------------------------------------------------
# Staging Environment Configuration
#------------------------------------------------------------------------------
# Optimized for: Production-like testing, pre-release validation
# 
# INDUSTRY CONTEXT:
# Staging environments prioritize:
# - Similar architecture to production (catch config issues)
# - Scaled down resources (cost management)
# - Real monitoring and alerting (test observability)
# - Reasonable backup retention (test recovery procedures)
#
# The goal: If it works in staging, it should work in production.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# General
#------------------------------------------------------------------------------

environment  = "staging"
aws_region   = "us-east-1"
project_name = "iac-pipeline"

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
# Enable NAT Gateway for realistic testing of private subnet workloads

vpc_cidr                 = "10.1.0.0/16" # Different CIDR from dev (allows VPC peering if needed)
az_count                 = 2
enable_nat_gateway       = true # Enable for realistic testing
enable_flow_logs         = true # Test log aggregation
flow_logs_retention_days = 7    # Short retention to manage costs

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
# Small but realistic instance size

instance_type         = "t3.small" # Step up from micro
instance_count        = 1          # Single instance (scale up for load testing)
instance_architecture = "x86_64"

root_volume_size       = 30 # More realistic size
root_volume_iops       = 3000
root_volume_throughput = 125

associate_public_ip           = false
enable_detailed_monitoring    = true # Test monitoring
create_cloudwatch_alarms      = true # Test alerting
cpu_alarm_threshold           = 80
enable_termination_protection = false # Still allow easy cleanup

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
# Production-like settings but smaller instance

db_engine         = "postgres"
db_engine_version = "15"
db_instance_class = "db.t3.small" # Step up from micro

db_allocated_storage     = 50  # More realistic
db_max_allocated_storage = 100 # Room for growth
db_storage_iops          = 3000
db_storage_throughput    = 125

db_name     = "appdb"
db_username = "dbadmin"

db_multi_az                   = false # Save costs, but test with true occasionally
db_backup_retention_period    = 7     # Week of backups
db_enable_deletion_protection = false # Allow cleanup
db_skip_final_snapshot        = false # Create snapshot on destroy

db_enable_performance_insights    = true
db_performance_insights_retention = 7  # Free tier
db_monitoring_interval            = 60 # Enable enhanced monitoring

db_create_cloudwatch_alarms        = true # Test alerting
db_cpu_alarm_threshold             = 80
db_free_storage_alarm_threshold    = 10  # GB
db_freeable_memory_alarm_threshold = 256 # MB
db_max_connections_alarm_threshold = 50

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

tags = {
  Environment = "staging"
  Project     = "iac-pipeline"
  ManagedBy   = "terraform"
  CostCenter  = "staging"
}