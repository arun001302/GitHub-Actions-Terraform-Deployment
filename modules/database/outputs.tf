#------------------------------------------------------------------------------
# Database Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Connection Information
#------------------------------------------------------------------------------

output "endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "RDS instance hostname (without port)"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Name of the default database"
  value       = aws_db_instance.main.db_name
}

#------------------------------------------------------------------------------
# Secrets Manager Outputs
#------------------------------------------------------------------------------

output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_credentials.name
}

#------------------------------------------------------------------------------
# Instance Identifiers
#------------------------------------------------------------------------------

output "instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

#------------------------------------------------------------------------------
# Application Configuration Outputs
#------------------------------------------------------------------------------

output "jdbc_connection_string" {
  description = "JDBC connection string (for Java applications)"
  value       = "jdbc:${var.engine}://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}

output "connection_info" {
  description = "Connection information map"
  value = {
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    engine   = aws_db_instance.main.engine
  }
}

output "environment_variables" {
  description = "Environment variables for application configuration"
  value = {
    DB_HOST       = aws_db_instance.main.address
    DB_PORT       = tostring(aws_db_instance.main.port)
    DB_NAME       = aws_db_instance.main.db_name
    DB_ENGINE     = aws_db_instance.main.engine
    DB_SECRET_ARN = aws_secretsmanager_secret.db_credentials.arn
  }
}

#------------------------------------------------------------------------------
# Module Summary Output
#------------------------------------------------------------------------------

output "database_summary" {
  description = "Summary of database resources created"
  value = {
    environment           = var.environment
    identifier            = aws_db_instance.main.identifier
    engine                = aws_db_instance.main.engine
    engine_version        = aws_db_instance.main.engine_version_actual
    instance_class        = aws_db_instance.main.instance_class
    endpoint              = aws_db_instance.main.endpoint
    database_name         = aws_db_instance.main.db_name
    multi_az              = aws_db_instance.main.multi_az
    storage_gb            = aws_db_instance.main.allocated_storage
    storage_encrypted     = aws_db_instance.main.storage_encrypted
    backup_retention_days = aws_db_instance.main.backup_retention_period
    performance_insights  = aws_db_instance.main.performance_insights_enabled
    deletion_protection   = aws_db_instance.main.deletion_protection
    secret_arn            = aws_secretsmanager_secret.db_credentials.arn
  }
}
