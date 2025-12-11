#------------------------------------------------------------------------------
# Bootstrap Main Configuration
#------------------------------------------------------------------------------
# Creates the foundational infrastructure for Terraform remote state:
# - S3 bucket for state storage
# - DynamoDB table for state locking
#
# INDUSTRY CONTEXT:
# This bootstrap pattern is standard in enterprise Terraform deployments.
# The resources created here are "meta-infrastructure" - infrastructure
# that enables you to safely manage other infrastructure.
#
# Key security considerations implemented:
# 1. Versioning: Enables state recovery if corruption occurs
# 2. Encryption: Protects sensitive data in state files
# 3. Public access blocks: Defense in depth against misconfigurations
# 4. DynamoDB locking: Prevents concurrent modification race conditions
#------------------------------------------------------------------------------

locals {
  # Generate DynamoDB table name if not explicitly provided
  dynamodb_table_name = var.dynamodb_table_name != null ? var.dynamodb_table_name : "${var.project_name}-terraform-locks"

  # Common tags applied to all resources (in addition to provider default_tags)
  common_tags = {
    Component = "state-backend"
  }
}

#------------------------------------------------------------------------------
# S3 Bucket for Terraform State
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# The state file contains sensitive information including:
# - Resource IDs and ARNs
# - Potentially secrets if not properly managed
# - Infrastructure topology (security concern if leaked)
#
# Therefore, we apply defense-in-depth security controls.
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Prevent accidental deletion of this critical resource
  # In production, you'd set this to true
  # For learning/portfolio, we keep it false for easy cleanup
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = var.state_bucket_name
  })

  lifecycle {
    # INDUSTRY CONTEXT:
    # prevent_destroy is a safety net. If someone runs `terraform destroy`,
    # Terraform will error out instead of deleting this bucket.
    # Remove or set to false only when intentionally decommissioning.
    prevent_destroy = false # Set to true in production
  }
}

#------------------------------------------------------------------------------
# S3 Bucket Versioning
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# Versioning is CRITICAL for state files. Scenarios where it saves you:
# - Corrupted state from failed applies
# - Accidental state deletion
# - Need to roll back to previous infrastructure state
# - Audit trail of state changes over time
#------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

#------------------------------------------------------------------------------
# S3 Bucket Server-Side Encryption
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# Encryption at rest is a compliance requirement in most enterprises.
# We use SSE-S3 (AES-256) which is:
# - Free (no additional cost)
# - Automatic (no key management needed)
# - Sufficient for most compliance frameworks
#
# For stricter requirements, you'd use SSE-KMS with customer-managed keys.
#------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

#------------------------------------------------------------------------------
# S3 Bucket Public Access Block
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# This is defense in depth. Even if someone misconfigures a bucket policy,
# these settings prevent the bucket from ever being publicly accessible.
# This is now an AWS best practice and required by many compliance frameworks.
#
# ALL FOUR settings should be true for state buckets - no exceptions.
#------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# DynamoDB Table for State Locking
#------------------------------------------------------------------------------
# INDUSTRY CONTEXT:
# Terraform uses DynamoDB for distributed locking. When `terraform apply` runs:
# 1. Terraform writes a lock record to this table
# 2. If another process tries to acquire the lock, it fails/waits
# 3. After the operation completes, the lock is released
#
# The table MUST have a primary key named "LockID" (Terraform requirement).
#
# PAY_PER_REQUEST billing is ideal because:
# - State locking is infrequent (only during terraform operations)
# - No need to manage capacity
# - Cost is effectively $0 for typical usage patterns
#------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.dynamodb_table_name
  billing_mode = var.dynamodb_billing_mode

  # CRITICAL: This attribute name is required by Terraform
  # Do not change "LockID" - it's hardcoded in Terraform's backend code
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S" # String type
  }

  # Point-in-time recovery for additional safety
  point_in_time_recovery {
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = local.dynamodb_table_name
  })

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}