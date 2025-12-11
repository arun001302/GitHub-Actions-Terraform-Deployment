#------------------------------------------------------------------------------
# Database Module - Main Configuration
#------------------------------------------------------------------------------
# Creates an RDS database instance with production-ready defaults.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------

locals {
  common_tags = merge(var.tags, {
    Module = "database"
  })

  name_prefix = "${var.environment}-db"

  default_ports = {
    postgres = 5432
    mysql    = 3306
    mariadb  = 3306
  }

  db_port = var.db_port != null ? var.db_port : local.default_ports[var.engine]

  engine_family = {
    postgres = "postgres${split(".", var.engine_version)[0]}"
    mysql    = "mysql${var.engine_version}"
    mariadb  = "mariadb${var.engine_version}"
  }
}

#------------------------------------------------------------------------------
# Random Password Generation
#------------------------------------------------------------------------------

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#------------------------------------------------------------------------------
# AWS Secrets Manager - Store Database Credentials
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${local.name_prefix}-credentials"
  description             = "Database credentials for ${var.environment} environment"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username          = var.master_username
    password          = random_password.master.result
    engine            = var.engine
    host              = aws_db_instance.main.address
    port              = local.db_port
    dbname            = var.database_name
    connection_string = "${var.engine}://${var.master_username}:${random_password.master.result}@${aws_db_instance.main.address}:${local.db_port}/${var.database_name}"
  })

  depends_on = [aws_db_instance.main]
}

#------------------------------------------------------------------------------
# DB Subnet Group
#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-subnet-group"
  description = "Database subnet group for ${var.environment}"
  subnet_ids  = var.subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-subnet-group"
  })
}

#------------------------------------------------------------------------------
# DB Parameter Group
#------------------------------------------------------------------------------

resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-params"
  family      = var.parameter_group_family != null ? var.parameter_group_family : local.engine_family[var.engine]
  description = "Database parameter group for ${var.environment}"

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name  = "log_statement"
      value = var.enable_query_logging ? "all" : "none"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []
    content {
      name  = "log_min_duration_statement"
      value = var.slow_query_log_threshold
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name  = "slow_query_log"
      value = var.enable_query_logging ? "1" : "0"
    }
  }

  dynamic "parameter" {
    for_each = contains(["mysql", "mariadb"], var.engine) ? [1] : []
    content {
      name  = "long_query_time"
      value = var.slow_query_log_threshold / 1000
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# IAM Role for Enhanced Monitoring
#------------------------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${local.name_prefix}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#------------------------------------------------------------------------------
# RDS Instance
#------------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-instance"

  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  iops                  = var.storage_iops
  storage_throughput    = var.storage_throughput

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = local.db_port

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  delete_automated_backups  = var.environment != "prod"
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-final-snapshot" : null

  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  enabled_cloudwatch_logs_exports       = var.cloudwatch_logs_exports

  deletion_protection = var.enable_deletion_protection
  apply_immediately   = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance"
  })

  depends_on = [
    aws_db_subnet_group.main,
    aws_db_parameter_group.main,
    aws_iam_role_policy_attachment.rds_monitoring
  ]

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [password]
  }
}

#------------------------------------------------------------------------------
# CloudWatch Alarms
#------------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_description = "RDS CPU utilization exceeded ${var.cpu_alarm_threshold}%"
  alarm_actions     = var.alarm_actions
  ok_actions        = var.alarm_actions

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.free_storage_alarm_threshold * 1024 * 1024 * 1024

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_description = "RDS free storage space below ${var.free_storage_alarm_threshold}GB"
  alarm_actions     = var.alarm_actions
  ok_actions        = var.alarm_actions

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-freeable-memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.freeable_memory_alarm_threshold * 1024 * 1024

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_description = "RDS freeable memory below ${var.freeable_memory_alarm_threshold}MB"
  alarm_actions     = var.alarm_actions
  ok_actions        = var.alarm_actions

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.max_connections_alarm_threshold

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }

  alarm_description = "RDS database connections exceeded ${var.max_connections_alarm_threshold}"
  alarm_actions     = var.alarm_actions
  ok_actions        = var.alarm_actions

  tags = local.common_tags
}