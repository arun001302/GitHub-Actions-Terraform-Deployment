#------------------------------------------------------------------------------
# Security Module - Outputs
#------------------------------------------------------------------------------
# Exports security group IDs and IAM role ARNs for other modules.
#
# INDUSTRY CONTEXT:
# Security module outputs are consumed by:
# - Compute module: Needs SG IDs and instance profile for EC2
# - Database module: Needs RDS security group ID
# - Load balancer configuration: Needs ALB security group ID
# - CI/CD pipelines: May need role ARNs for deployment permissions
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Security Group IDs
#------------------------------------------------------------------------------

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application/EC2 security group"
  value       = aws_security_group.app.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group (null if not created)"
  value       = var.create_bastion_sg ? aws_security_group.bastion[0].id : null
}

#------------------------------------------------------------------------------
# Security Group ARNs
#------------------------------------------------------------------------------

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

output "app_security_group_arn" {
  description = "ARN of the application/EC2 security group"
  value       = aws_security_group.app.arn
}

output "rds_security_group_arn" {
  description = "ARN of the RDS security group"
  value       = aws_security_group.rds.arn
}

#------------------------------------------------------------------------------
# IAM Role Outputs
#------------------------------------------------------------------------------

output "ec2_iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2.arn
}

output "ec2_iam_role_name" {
  description = "Name of the IAM role for EC2 instances"
  value       = aws_iam_role.ec2.name
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2.arn
}

#------------------------------------------------------------------------------
# Grouped Outputs for Convenience
#------------------------------------------------------------------------------

output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb     = aws_security_group.alb.id
    app     = aws_security_group.app.id
    rds     = aws_security_group.rds.id
    bastion = var.create_bastion_sg ? aws_security_group.bastion[0].id : null
  }
}

output "security_group_arns" {
  description = "Map of all security group ARNs"
  value = {
    alb     = aws_security_group.alb.arn
    app     = aws_security_group.app.arn
    rds     = aws_security_group.rds.arn
    bastion = var.create_bastion_sg ? aws_security_group.bastion[0].arn : null
  }
}

#------------------------------------------------------------------------------
# IAM Outputs for CI/CD Integration
#------------------------------------------------------------------------------

output "iam_resources" {
  description = "Map of IAM resource identifiers"
  value = {
    ec2_role_arn          = aws_iam_role.ec2.arn
    ec2_role_name         = aws_iam_role.ec2.name
    instance_profile_name = aws_iam_instance_profile.ec2.name
    instance_profile_arn  = aws_iam_instance_profile.ec2.arn
  }
}

#------------------------------------------------------------------------------
# Configuration Reference Outputs
#------------------------------------------------------------------------------

output "configuration" {
  description = "Security module configuration reference"
  value = {
    app_port           = var.app_port
    db_port            = var.db_port
    ssm_access_enabled = var.enable_ssm_access
    bastion_enabled    = var.create_bastion_sg
  }
}

#------------------------------------------------------------------------------
# Module Summary Output
#------------------------------------------------------------------------------

output "security_summary" {
  description = "Summary of security resources created"
  value = {
    environment             = var.environment
    security_groups_created = var.create_bastion_sg ? 4 : 3
    alb_sg_id               = aws_security_group.alb.id
    app_sg_id               = aws_security_group.app.id
    rds_sg_id               = aws_security_group.rds.id
    bastion_sg_id           = var.create_bastion_sg ? aws_security_group.bastion[0].id : "not created"
    ec2_role_name           = aws_iam_role.ec2.name
    instance_profile_name   = aws_iam_instance_profile.ec2.name
    ssm_access_enabled      = var.enable_ssm_access
  }
}
