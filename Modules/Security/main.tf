#------------------------------------------------------------------------------
# Security Module - Main Configuration
#------------------------------------------------------------------------------
# Creates security groups and IAM roles for the infrastructure.
#
# INDUSTRY CONTEXT:
# Security is foundational - compute and database resources cannot launch
# without security groups. This module implements defense-in-depth:
#
# 1. Network Security (Security Groups):
#    - Layered access: Internet → ALB → App → Database
#    - Each layer only accepts traffic from the layer above
#    - Principle of least privilege for network access
#
# 2. Identity Security (IAM Roles):
#    - No hardcoded credentials in application code
#    - Temporary credentials via instance profiles
#    - Granular permissions per resource type
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------

locals {
  common_tags = merge(var.tags, {
    Module = "security"
  })

  # Standard ports for reference
  https_port = 443
  http_port  = 80
}

#------------------------------------------------------------------------------
# ALB Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from anywhere (for HTTPS redirect)"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from anywhere"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_to_app" {
  type                     = "egress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "Allow traffic to application servers"
  security_group_id        = aws_security_group.alb.id
}

#------------------------------------------------------------------------------
# Application/EC2 Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB"
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  description       = "Allow communication between app instances"
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_https" {
  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS outbound (AWS APIs, external services)"
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_http" {
  type              = "egress"
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP outbound (package updates)"
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_to_db" {
  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  description              = "Allow access to RDS database"
  security_group_id        = aws_security_group.app.id
}

#------------------------------------------------------------------------------
# RDS Security Group
#------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_from_app" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "Allow database access from application servers"
  security_group_id        = aws_security_group.rds.id
}

#------------------------------------------------------------------------------
# Bastion Security Group (Optional)
#------------------------------------------------------------------------------

resource "aws_security_group" "bastion" {
  count = var.create_bastion_sg ? 1 : 0

  name        = "${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-bastion-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "bastion_ssh_ingress" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.bastion_allowed_cidrs
  description       = "Allow SSH from specified IP ranges"
  security_group_id = aws_security_group.bastion[0].id
}

resource "aws_security_group_rule" "bastion_to_app" {
  count = var.create_bastion_sg ? 1 : 0

  type                     = "egress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  description              = "Allow SSH to application servers"
  security_group_id        = aws_security_group.bastion[0].id
}

resource "aws_security_group_rule" "bastion_egress_https" {
  count = var.create_bastion_sg ? 1 : 0

  type              = "egress"
  from_port         = local.https_port
  to_port           = local.https_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS outbound"
  security_group_id = aws_security_group.bastion[0].id
}

resource "aws_security_group_rule" "app_from_bastion" {
  count = var.create_bastion_sg ? 1 : 0

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion[0].id
  description              = "Allow SSH from bastion host"
  security_group_id        = aws_security_group.app.id
}

#------------------------------------------------------------------------------
# IAM Role for EC2 Instances
#------------------------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# SSM Session Manager Policy
#------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  count = var.enable_ssm_access ? 1 : 0

  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#------------------------------------------------------------------------------
# CloudWatch Logs Policy
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.environment}-cloudwatch-logs-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# CloudWatch Metrics Policy
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "cloudwatch_metrics" {
  name = "${var.environment}-cloudwatch-metrics-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# EC2 Instance Profile
#------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2.name

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Optional: S3 Access Policy
#------------------------------------------------------------------------------

resource "aws_iam_role_policy" "s3_access" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0

  name = "${var.environment}-s3-access-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = concat(
          var.s3_bucket_arns,
          [for arn in var.s3_bucket_arns : "${arn}/*"]
        )
      }
    ]
  })
}