#------------------------------------------------------------------------------
# Networking Module - Outputs
#------------------------------------------------------------------------------
# Exports values that other modules and the root configuration need.
#
# INDUSTRY CONTEXT:
# Well-designed module outputs follow these principles:
# 1. Export IDs for resource references (other modules need these)
# 2. Export ARNs for IAM policies and cross-account access
# 3. Export computed values that callers shouldn't recalculate
# 4. Group related outputs logically
# 5. Include descriptions for documentation
#
# These outputs enable loose coupling between modules. The compute module
# doesn't need to know HOW networking creates subnets - it just needs
# the subnet IDs to place EC2 instances.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# VPC Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

#------------------------------------------------------------------------------
# Subnet Outputs
#------------------------------------------------------------------------------

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_arns" {
  description = "List of public subnet ARNs"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of private subnet ARNs"
  value       = aws_subnet.private[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

#------------------------------------------------------------------------------
# Availability Zone Outputs
#------------------------------------------------------------------------------

output "availability_zones" {
  description = "List of Availability Zones used"
  value       = local.azs
}

output "az_count" {
  description = "Number of Availability Zones in use"
  value       = local.az_count
}

#------------------------------------------------------------------------------
# Gateway Outputs
#------------------------------------------------------------------------------

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (null if not created)"
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway (null if not created)"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

#------------------------------------------------------------------------------
# Route Table Outputs
#------------------------------------------------------------------------------

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

#------------------------------------------------------------------------------
# Flow Logs Outputs
#------------------------------------------------------------------------------

output "flow_logs_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_logs_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for VPC Flow Logs"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].arn : null
}

#------------------------------------------------------------------------------
# Computed Outputs for Common Use Cases
#------------------------------------------------------------------------------

output "subnet_ids_by_tier" {
  description = "Map of subnet IDs grouped by tier (public/private)"
  value = {
    public  = aws_subnet.public[*].id
    private = aws_subnet.private[*].id
  }
}

output "subnet_ids_by_az" {
  description = "Map of subnet IDs grouped by Availability Zone"
  value = {
    for idx, az in local.azs : az => {
      public  = aws_subnet.public[idx].id
      private = aws_subnet.private[idx].id
    }
  }
}

#------------------------------------------------------------------------------
# Database Subnet Group Ready Output
#------------------------------------------------------------------------------

output "database_subnet_ids" {
  description = "Subnet IDs for RDS subnet group (uses private subnets)"
  value       = aws_subnet.private[*].id
}

#------------------------------------------------------------------------------
# Module Summary Output
#------------------------------------------------------------------------------

output "networking_summary" {
  description = "Summary of networking resources created"
  value = {
    vpc_id               = aws_vpc.main.id
    vpc_cidr             = aws_vpc.main.cidr_block
    az_count             = local.az_count
    availability_zones   = local.azs
    public_subnet_count  = length(aws_subnet.public)
    private_subnet_count = length(aws_subnet.private)
    nat_gateway_enabled  = var.enable_nat_gateway
    flow_logs_enabled    = var.enable_flow_logs
  }
}