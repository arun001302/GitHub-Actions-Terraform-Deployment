#------------------------------------------------------------------------------
# Development Environment Configuration
#------------------------------------------------------------------------------
# Optimized for: Cost savings, fast iteration, learning
# 
# INDUSTRY CONTEXT:
# Dev environments prioritize:
# - Lowest cost (smallest instances, no redundancy)
# - Fast provisioning/destruction
# - Easy experimentation
# - Acceptable downtime (no Multi-AZ needed)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# General
#------------------------------------------------------------------------------

environment  = "dev"
aws_region   = "us-east-1"
project_name = "iac-pipeline"

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------
# Smaller CIDR, fewer AZs, no NAT Gateway to save ~$32/month

vpc_cidr           = "10.0.0.0/16"
az_count           = 2
enable_nat_gateway = false # Save ~$32/month - instances won't have outbound internet from private subnets
enable_flow_logs   = false # Save on CloudWatch costs

#------------------------------------------------------------------------------
# Security
#------------------------------------------------------------------------------

app_port          = 8080
db_port           = 5432
enable_ssm_access = true  # Always enable - secure shell access
create_bastion_sg = false # Use SSM instead

#------------------------------------------------------------------------------
# Compute
#------------------------------------------------------------------------------
# Smallest instance, single instance, minimal storage

instance_type         = "t3.micro" # Free tier eligible
instance_count        = 1
instance_architecture = "x86_64"

root_volume_size       = 30   # Minimum practical size
root_volume_iops       = 3000 # GP3 baseline (free)
root_volume_throughput = 125  # GP3 baseline (free)

associate_public_ip           = false
enable_detailed_monitoring    = false # Save on CloudWatch costs
create_cloudwatch_alarms      = false # Optional for dev
enable_termination_protection = false # Easy cleanup

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
# Smallest instance, no Multi-AZ, minimal backups

db_engine         = "postgres"
db_engine_version = "15"
db_instance_class = "db.t3.micro" # Smallest RDS instance

db_allocated_storage     = 20   # Minimum for GP3
db_max_allocated_storage = 50   # Allow some autoscaling
db_storage_iops          = null # GP3 baseline
db_storage_throughput    = null # GP3 baseline

db_name     = "appdb"
db_username = "dbadmin"

db_multi_az                   = false # No HA needed for dev
db_backup_retention_period    = 1     # Minimum backup retention
db_enable_deletion_protection = false # Easy cleanup
db_skip_final_snapshot        = true  # Don't create snapshot on destroy

db_enable_performance_insights    = true # Free for 7 days retention
db_performance_insights_retention = 7    # Free tier
db_monitoring_interval            = 0    # Disable enhanced monitoring

db_create_cloudwatch_alarms = false # Optional for dev

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

tags = {
  Environment = "dev"
  Project     = "iac-pipeline"
  ManagedBy   = "terraform"
  CostCenter  = "development"
}