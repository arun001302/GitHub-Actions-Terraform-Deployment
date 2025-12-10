#------------------------------------------------------------------------------
# Root Module - Main Configuration
#------------------------------------------------------------------------------
# This is the entry point for the infrastructure. It composes all modules
# together, passing outputs from one module as inputs to another.
#
# INDUSTRY CONTEXT:
# The root module follows the "composition" pattern:
# - Modules are like LEGO blocks (reusable, self-contained)
# - Root main.tf assembles the blocks into a complete system
# - Data flows: Networking → Security → Compute/Database
#
# This separation enables:
# - Reuse modules across projects
# - Test modules independently
# - Clear dependency chain
# - Easier troubleshooting
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Networking Module
#------------------------------------------------------------------------------
# Creates: VPC, Subnets, Internet Gateway, NAT Gateway, Route Tables
#
# This module has NO dependencies - it's the foundation everything else
# builds upon.
#------------------------------------------------------------------------------

module "networking" {
  source = "./modules/networking"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  enable_flow_logs   = var.enable_flow_logs

  tags = var.tags
}

#------------------------------------------------------------------------------
# Security Module
#------------------------------------------------------------------------------
# Creates: Security Groups (ALB, App, RDS), IAM Role, Instance Profile
#
# DEPENDS ON: Networking (needs VPC ID)
#
# Security groups must be created in a VPC, so we pass the vpc_id
# from the networking module output.
#------------------------------------------------------------------------------

module "security" {
  source = "./modules/security"

  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  app_port          = var.app_port
  db_port           = var.db_port
  enable_ssm_access = var.enable_ssm_access
  create_bastion_sg = var.create_bastion_sg

  tags = var.tags
}

#------------------------------------------------------------------------------
# Compute Module
#------------------------------------------------------------------------------
# Creates: Launch Template, EC2 Instance(s), CloudWatch Alarms
#
# DEPENDS ON: Networking (needs subnet IDs), Security (needs SG and IAM)
#
# EC2 instances need:
# - A subnet to launch in (from networking)
# - A security group for network access (from security)
# - An IAM instance profile for AWS permissions (from security)
#------------------------------------------------------------------------------

module "compute" {
  source = "./modules/compute"

  environment           = var.environment
  subnet_ids            = module.networking.private_subnet_ids
  security_group_id     = module.security.app_security_group_id
  instance_profile_name = module.security.ec2_instance_profile_name

  instance_type         = var.instance_type
  instance_count        = var.instance_count
  instance_architecture = var.instance_architecture

  root_volume_size       = var.root_volume_size
  root_volume_iops       = var.root_volume_iops
  root_volume_throughput = var.root_volume_throughput

  associate_public_ip           = var.associate_public_ip
  enable_detailed_monitoring    = var.enable_detailed_monitoring
  create_cloudwatch_alarms      = var.create_cloudwatch_alarms
  enable_termination_protection = var.enable_termination_protection

  tags = var.tags
}

#------------------------------------------------------------------------------
# Database Module
#------------------------------------------------------------------------------
# Creates: RDS Instance, DB Subnet Group, Parameter Group, Secrets Manager
#
# DEPENDS ON: Networking (needs subnet IDs), Security (needs SG)
#
# RDS needs:
# - Subnets in at least 2 AZs (from networking)
# - A security group for network access (from security)
#------------------------------------------------------------------------------

module "database" {
  source = "./modules/database"

  environment       = var.environment
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.security.rds_security_group_id

  engine          = var.db_engine
  engine_version  = var.db_engine_version
  instance_class  = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_iops          = var.db_storage_iops
  storage_throughput    = var.db_storage_throughput

  database_name   = var.db_name
  master_username = var.db_username

  multi_az                   = var.db_multi_az
  backup_retention_period    = var.db_backup_retention_period
  enable_deletion_protection = var.db_enable_deletion_protection

  enable_performance_insights    = var.db_enable_performance_insights
  performance_insights_retention = var.db_performance_insights_retention
  monitoring_interval            = var.db_monitoring_interval

  create_cloudwatch_alarms = var.db_create_cloudwatch_alarms

  tags = var.tags
}
