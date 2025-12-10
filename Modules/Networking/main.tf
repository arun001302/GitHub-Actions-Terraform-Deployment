#------------------------------------------------------------------------------
# Networking Module - Main Configuration
#------------------------------------------------------------------------------
# Creates a production-ready VPC with public and private subnets across
# multiple Availability Zones.
#
# INDUSTRY CONTEXT:
# This module follows AWS Well-Architected Framework best practices:
# - Multi-AZ deployment for high availability
# - Public/Private subnet separation for security
# - NAT Gateway for secure outbound internet access from private subnets
# - Proper tagging for cost allocation and resource identification
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
# Dynamically fetch available AZs instead of hardcoding.
#
# INDUSTRY CONTEXT:
# Hardcoding AZs (us-east-1a, us-east-1b) is fragile because:
# - AZ names are account-specific (your us-east-1a might be different hardware
#   than another account's us-east-1a)
# - Some AZs may not support all instance types
# - New regions may have different AZ counts
#
# Using data sources makes your module portable across regions and accounts.
#------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"

  # Exclude Local Zones and Wavelength Zones - they have different capabilities
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------
# Computed values used throughout the module.
#
# INDUSTRY CONTEXT:
# Locals reduce repetition and make the code more maintainable.
# If you need to change the naming convention, you change it in one place.
#------------------------------------------------------------------------------

locals {
  # Determine how many AZs to use (limited by what's available in the region)
  az_count = min(var.az_count, length(data.aws_availability_zones.available.names))

  # List of AZs we'll actually use
  azs = slice(data.aws_availability_zones.available.names, 0, local.az_count)

  # Common tags applied to all resources in this module
  common_tags = merge(var.tags, {
    Module = "networking"
  })
}

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------
# The Virtual Private Cloud is your isolated network in AWS.
#
# INDUSTRY CONTEXT:
# - enable_dns_hostnames: Required for RDS, ECS, and many AWS services
# - enable_dns_support: Required for Route 53 private hosted zones
# - These are disabled by default, but almost always needed in practice
#------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc"
  })
}

#------------------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------------------
# Enables internet access for resources in public subnets.
#
# INDUSTRY CONTEXT:
# - One IGW per VPC (AWS limit)
# - Provides both inbound and outbound internet access
# - Resources must have public IPs AND be in a subnet with IGW route
#------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw"
  })
}

#------------------------------------------------------------------------------
# Public Subnets
#------------------------------------------------------------------------------
# Subnets with direct internet access via Internet Gateway.
#
# INDUSTRY CONTEXT:
# - map_public_ip_on_launch: Instances get public IPs automatically
# - We create one subnet per AZ for high availability
# - Use cidrsubnet() function for programmatic CIDR calculation
#
# cidrsubnet() explained:
#   cidrsubnet("10.0.0.0/16", 8, 1) = "10.0.1.0/24"
#   - Base: 10.0.0.0/16
#   - Newbits: 8 (16 + 8 = /24 subnet)
#   - Netnum: 1 (the 1st /24 block = 10.0.1.0/24)
#------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-subnet-${local.azs[count.index]}"
    Tier = "public"
  })
}

#------------------------------------------------------------------------------
# Private Subnets
#------------------------------------------------------------------------------
# Subnets without direct internet access - for internal resources.
#
# INDUSTRY CONTEXT:
# - No public IPs assigned
# - Cannot be reached from internet (security benefit)
# - Can reach internet via NAT Gateway (for updates, API calls, etc.)
# - Ideal for: application servers, databases, internal services
#
# CIDR calculation: We start at netnum 10 to leave room for future subnet types
# (e.g., database subnets at 20+, cache subnets at 30+)
#------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-subnet-${local.azs[count.index]}"
    Tier = "private"
  })
}

#------------------------------------------------------------------------------
# Elastic IP for NAT Gateway
#------------------------------------------------------------------------------
# Static public IP for the NAT Gateway.
#
# INDUSTRY CONTEXT:
# - NAT Gateway requires an Elastic IP
# - We only create this if NAT Gateway is enabled (cost optimization)
# - For multi-AZ NAT (production), you'd create one EIP per AZ
# - Single NAT is acceptable for dev/staging to save costs (~$32/month per NAT)
#------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-eip"
  })

  # EIP may require IGW to exist
  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# NAT Gateway
#------------------------------------------------------------------------------
# Enables outbound internet access for private subnets.
#
# INDUSTRY CONTEXT:
# Why NAT Gateway instead of NAT Instance?
# - Managed service (no patching, high availability within AZ)
# - Scales automatically up to 45 Gbps
# - More expensive but operationally simpler
#
# Cost consideration:
# - ~$0.045/hour (~$32/month) + data processing charges
# - For dev environments, consider disabling or using NAT Instance
# - For production, use one NAT per AZ for fault tolerance
#
# We place NAT in the FIRST public subnet. For production multi-AZ,
# you'd create one NAT per AZ.
#------------------------------------------------------------------------------

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-gateway"
  })

  # NAT Gateway needs IGW to be available
  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# Public Route Table
#------------------------------------------------------------------------------
# Routes traffic from public subnets to the Internet Gateway.
#
# INDUSTRY CONTEXT:
# - One route table can be associated with multiple subnets
# - The 0.0.0.0/0 route sends all non-local traffic to the IGW
# - Local route (to VPC CIDR) is implicit and automatic
#------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

#------------------------------------------------------------------------------
# Public Route Table Associations
#------------------------------------------------------------------------------
# Links public subnets to the public route table.
#------------------------------------------------------------------------------

resource "aws_route_table_association" "public" {
  count = local.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#------------------------------------------------------------------------------
# Private Route Table
#------------------------------------------------------------------------------
# Routes traffic from private subnets.
#
# INDUSTRY CONTEXT:
# - If NAT Gateway exists: routes 0.0.0.0/0 to NAT for outbound internet
# - If no NAT Gateway: private subnets have no internet access (most isolated)
#
# We use dynamic block to conditionally add the NAT route only when enabled.
#------------------------------------------------------------------------------

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # Conditionally add NAT Gateway route
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-rt"
  })
}

#------------------------------------------------------------------------------
# Private Route Table Associations
#------------------------------------------------------------------------------
# Links private subnets to the private route table.
#
# INDUSTRY CONTEXT:
# For production with multi-AZ NAT, you'd create separate route tables
# per AZ, each pointing to its local NAT Gateway. This ensures that if
# one AZ goes down, the other AZs can still reach the internet.
#
# For simplicity and cost savings, we use a single route table here.
#------------------------------------------------------------------------------

resource "aws_route_table_association" "private" {
  count = local.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

#------------------------------------------------------------------------------
# VPC Flow Logs (Optional but Recommended)
#------------------------------------------------------------------------------
# Captures network traffic metadata for security and troubleshooting.
#
# INDUSTRY CONTEXT:
# Flow logs are critical for:
# - Security incident investigation
# - Network troubleshooting
# - Compliance requirements (PCI-DSS, HIPAA, etc.)
#
# We make this optional because:
# - Adds cost (CloudWatch Logs storage)
# - May not be needed for dev/learning environments
# - Can be enabled per environment via variables
#------------------------------------------------------------------------------

resource "aws_flow_log" "main" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.main.id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  max_aggregation_interval = 60

  tags = merge(local.common_tags, {
    Name = "${var.environment}-vpc-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc-flow-logs/${var.environment}"
  retention_in_days = var.flow_logs_retention_days

  tags = local.common_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.environment}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}