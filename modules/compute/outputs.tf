#------------------------------------------------------------------------------
# Compute Module - Outputs
#------------------------------------------------------------------------------
# Exports instance information for other modules and root configuration.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Instance IDs
#------------------------------------------------------------------------------

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "instance_id" {
  description = "ID of the first EC2 instance (convenience output)"
  value       = length(aws_instance.app) > 0 ? aws_instance.app[0].id : null
}

#------------------------------------------------------------------------------
# Instance ARNs
#------------------------------------------------------------------------------

output "instance_arns" {
  description = "List of EC2 instance ARNs"
  value       = aws_instance.app[*].arn
}

#------------------------------------------------------------------------------
# Network Information
#------------------------------------------------------------------------------

output "private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.app[*].private_ip
}

output "private_ip" {
  description = "Private IP of the first instance (convenience output)"
  value       = length(aws_instance.app) > 0 ? aws_instance.app[0].private_ip : null
}

output "public_ips" {
  description = "List of public IP addresses (empty if not assigned)"
  value       = aws_instance.app[*].public_ip
}

output "private_dns" {
  description = "List of private DNS names"
  value       = aws_instance.app[*].private_dns
}

output "public_dns" {
  description = "List of public DNS names (empty if no public IP)"
  value       = aws_instance.app[*].public_dns
}

#------------------------------------------------------------------------------
# Elastic IP Outputs
#------------------------------------------------------------------------------

output "elastic_ips" {
  description = "List of Elastic IP addresses (if created)"
  value       = aws_eip.app[*].public_ip
}

output "elastic_ip_allocation_ids" {
  description = "List of Elastic IP allocation IDs (if created)"
  value       = aws_eip.app[*].allocation_id
}

#------------------------------------------------------------------------------
# Launch Template Outputs
#------------------------------------------------------------------------------

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.app.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.app.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the launch template"
  value       = aws_launch_template.app.latest_version
}

output "launch_template_name" {
  description = "Name of the launch template"
  value       = aws_launch_template.app.name
}

#------------------------------------------------------------------------------
# AMI Information
#------------------------------------------------------------------------------

output "ami_id" {
  description = "AMI ID used for instances"
  value       = var.instance_architecture == "arm64" ? data.aws_ami.amazon_linux_arm.id : data.aws_ami.amazon_linux.id
}

output "ami_name" {
  description = "Name of the AMI used"
  value       = var.instance_architecture == "arm64" ? data.aws_ami.amazon_linux_arm.name : data.aws_ami.amazon_linux.name
}

#------------------------------------------------------------------------------
# Instance State Information
#------------------------------------------------------------------------------

output "instance_states" {
  description = "Map of instance IDs to their current state"
  value = {
    for instance in aws_instance.app : instance.id => instance.instance_state
  }
}

#------------------------------------------------------------------------------
# Availability Zone Distribution
#------------------------------------------------------------------------------

output "instance_availability_zones" {
  description = "Map of instance IDs to their Availability Zones"
  value = {
    for instance in aws_instance.app : instance.id => instance.availability_zone
  }
}

output "instances_by_az" {
  description = "Map of Availability Zones to instance IDs"
  value = {
    for az in distinct(aws_instance.app[*].availability_zone) : az => [
      for instance in aws_instance.app : instance.id if instance.availability_zone == az
    ]
  }
}

#------------------------------------------------------------------------------
# CloudWatch Alarm Outputs
#------------------------------------------------------------------------------

output "cloudwatch_alarm_arns" {
  description = "List of CloudWatch alarm ARNs (if created)"
  value = concat(
    aws_cloudwatch_metric_alarm.cpu_high[*].arn,
    aws_cloudwatch_metric_alarm.status_check[*].arn
  )
}

#------------------------------------------------------------------------------
# Grouped Outputs for Convenience
#------------------------------------------------------------------------------

output "instances" {
  description = "Map of instance details"
  value = {
    for idx, instance in aws_instance.app : instance.id => {
      id                = instance.id
      arn               = instance.arn
      private_ip        = instance.private_ip
      public_ip         = instance.public_ip
      private_dns       = instance.private_dns
      availability_zone = instance.availability_zone
      subnet_id         = instance.subnet_id
      state             = instance.instance_state
    }
  }
}

#------------------------------------------------------------------------------
# Target Group Registration Ready Output
#------------------------------------------------------------------------------

output "target_group_targets" {
  description = "Instance IDs formatted for ALB target group registration"
  value = [
    for instance in aws_instance.app : {
      id   = instance.id
      port = 8080
    }
  ]
}

#------------------------------------------------------------------------------
# Module Summary Output
#------------------------------------------------------------------------------

output "compute_summary" {
  description = "Summary of compute resources created"
  value = {
    environment         = var.environment
    instance_count      = var.instance_count
    instance_type       = var.instance_type
    architecture        = var.instance_architecture
    ami_id              = var.instance_architecture == "arm64" ? data.aws_ami.amazon_linux_arm.id : data.aws_ami.amazon_linux.id
    launch_template_id  = aws_launch_template.app.id
    instance_ids        = aws_instance.app[*].id
    private_ips         = aws_instance.app[*].private_ip
    availability_zones  = distinct(aws_instance.app[*].availability_zone)
    detailed_monitoring = var.enable_detailed_monitoring
    cloudwatch_alarms   = var.create_cloudwatch_alarms
  }
}

#------------------------------------------------------------------------------
# SSM Connection Helper
#------------------------------------------------------------------------------

output "ssm_connection_commands" {
  description = "AWS CLI commands to connect to instances via SSM"
  value = [
    for instance in aws_instance.app :
    "aws ssm start-session --target ${instance.id}"
  ]
}