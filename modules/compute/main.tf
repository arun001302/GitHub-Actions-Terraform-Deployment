#------------------------------------------------------------------------------
# Compute Module - Main Configuration
#------------------------------------------------------------------------------
# Creates EC2 instances and launch templates for application servers.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------

locals {
  common_tags = merge(var.tags, {
    Module = "compute"
  })

  name_prefix = "${var.environment}-app"

  default_user_data = <<-EOF
    #!/bin/bash
    set -e

    # Update system packages
    dnf update -y

    # Install common utilities
    dnf install -y \
      htop \
      vim \
      curl \
      wget \
      jq \
      unzip

    # Install and start SSM agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install CloudWatch agent
    dnf install -y amazon-cloudwatch-agent

    # Create application directory
    mkdir -p /opt/app
    chown ec2-user:ec2-user /opt/app

    # Log completion
    echo "User data script completed at $(date)" >> /var/log/user-data.log
  EOF
}

#------------------------------------------------------------------------------
# Data Source: Latest Amazon Linux 2023 AMI
#------------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = [var.instance_architecture]
  }
}

#------------------------------------------------------------------------------
# Data Source: Graviton AMI (ARM64) - Optional
#------------------------------------------------------------------------------

data "aws_ami" "amazon_linux_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

#------------------------------------------------------------------------------
# Launch Template
#------------------------------------------------------------------------------

resource "aws_launch_template" "app" {
  name_prefix = "${local.name_prefix}-lt-"
  description = "Launch template for ${var.environment} application servers"

  image_id      = var.instance_architecture == "arm64" ? data.aws_ami.amazon_linux_arm.id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # NOTE: Security groups are set on the instance, not here
  # This avoids the "Network interfaces and instance-level security groups" conflict

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
      iops                  = var.root_volume_iops
      throughput            = var.root_volume_throughput
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = var.user_data != "" ? base64encode(var.user_data) : base64encode(local.default_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-server"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-launch-template"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# EC2 Instance
#------------------------------------------------------------------------------

resource "aws_instance" "app" {
  count = var.instance_count

  ami                  = var.instance_architecture == "arm64" ? data.aws_ami.amazon_linux_arm.id : data.aws_ami.amazon_linux.id
  instance_type        = var.instance_type
  iam_instance_profile = var.instance_profile_name

  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = var.associate_public_ip

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    iops                  = var.root_volume_iops
    throughput            = var.root_volume_throughput
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = var.user_data != "" ? base64encode(var.user_data) : base64encode(local.default_user_data)

  monitoring = var.enable_detailed_monitoring

  tags = merge(local.common_tags, {
    Name = var.instance_count > 1 ? "${local.name_prefix}-server-${count.index + 1}" : "${local.name_prefix}-server"
  })

  disable_api_termination = var.enable_termination_protection

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      user_data,
    ]
  }
}

#------------------------------------------------------------------------------
# Elastic IP (Optional)
#------------------------------------------------------------------------------

resource "aws_eip" "app" {
  count = var.create_elastic_ip ? var.instance_count : 0

  domain   = "vpc"
  instance = aws_instance.app[count.index].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eip-${count.index + 1}"
  })

  depends_on = [aws_instance.app]
}

#------------------------------------------------------------------------------
# CloudWatch Alarms
#------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.create_cloudwatch_alarms ? var.instance_count : 0

  alarm_name          = "${local.name_prefix}-${count.index + 1}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  alarm_description = "CPU utilization exceeded ${var.cpu_alarm_threshold}% for ${local.name_prefix}-${count.index + 1}"

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  count = var.create_cloudwatch_alarms ? var.instance_count : 0

  alarm_name          = "${local.name_prefix}-${count.index + 1}-status-check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    InstanceId = aws_instance.app[count.index].id
  }

  alarm_description = "Status check failed for ${local.name_prefix}-${count.index + 1}"

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  tags = local.common_tags
}