#------------------------------------------------------------------------------
# Root Module - Outputs
#------------------------------------------------------------------------------
# Exposes key information from all modules for:
# - Other Terraform configurations (via remote state)
# - CI/CD pipelines
# - Documentation
# - Operational reference
#
# INDUSTRY CONTEXT:
# Root outputs aggregate the most important values from child modules.
# Not everything needs to be exposed - focus on:
# - Connection information (endpoints, IPs)
# - Resource identifiers (IDs, ARNs)
# - Security credentials references (secret ARNs, not actual secrets)
# - Operational summaries
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Networking Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "availability_zones" {
  description = "List of Availability Zones used"
  value       = module.networking.availability_zones
}

output "nat_gateway_ip" {
  description = "Public IP of NAT Gateway (if created)"
  value       = module.networking.nat_gateway_public_ip
}

#------------------------------------------------------------------------------
# Security Outputs
#------------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = module.security.app_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.security.rds_security_group_id
}

output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = module.security.ec2_iam_role_arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.security.ec2_instance_profile_name
}

#------------------------------------------------------------------------------
# Compute Outputs
#------------------------------------------------------------------------------

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = module.compute.instance_ids
}

output "instance_private_ips" {
  description = "List of EC2 private IP addresses"
  value       = module.compute.private_ips
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = module.compute.launch_template_id
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = module.compute.launch_template_latest_version
}

output "ssm_connection_commands" {
  description = "AWS CLI commands to connect to instances via SSM"
  value       = module.compute.ssm_connection_commands
}

#------------------------------------------------------------------------------
# Database Outputs
#------------------------------------------------------------------------------

output "db_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = module.database.endpoint
}

output "db_address" {
  description = "RDS instance hostname"
  value       = module.database.address
}

output "db_port" {
  description = "RDS instance port"
  value       = module.database.port
}

output "db_name" {
  description = "Name of the default database"
  value       = module.database.database_name
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = module.database.secret_arn
}

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = module.database.instance_id
}

#------------------------------------------------------------------------------
# Application Configuration Outputs
#------------------------------------------------------------------------------
# Pre-formatted outputs for application deployment.
#
# INDUSTRY CONTEXT:
# These outputs can be:
# - Injected into container environment variables
# - Used in application config files
# - Referenced by deployment scripts
#------------------------------------------------------------------------------

output "app_environment_variables" {
  description = "Environment variables for application configuration"
  value = {
    # Database connection
    DB_HOST       = module.database.address
    DB_PORT       = tostring(module.database.port)
    DB_NAME       = module.database.database_name
    DB_SECRET_ARN = module.database.secret_arn

    # AWS context
    AWS_REGION = var.aws_region
    ENVIRONMENT = var.environment

    # Infrastructure references
    VPC_ID              = module.networking.vpc_id
    PRIVATE_SUBNET_IDS  = join(",", module.networking.private_subnet_ids)
  }
}

#------------------------------------------------------------------------------
# Infrastructure Summary
#------------------------------------------------------------------------------
# Human-readable summary for quick reference.
#------------------------------------------------------------------------------

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment = var.environment
    region      = var.aws_region

    networking = {
      vpc_id             = module.networking.vpc_id
      vpc_cidr           = module.networking.vpc_cidr_block
      availability_zones = module.networking.availability_zones
      nat_gateway        = var.enable_nat_gateway ? "enabled" : "disabled"
    }

    compute = {
      instance_count = var.instance_count
      instance_type  = var.instance_type
      instance_ids   = module.compute.instance_ids
      private_ips    = module.compute.private_ips
    }

    database = {
      engine        = var.db_engine
      instance_class = var.db_instance_class
      endpoint      = module.database.endpoint
      multi_az      = var.db_multi_az
    }
  }
}