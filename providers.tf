#------------------------------------------------------------------------------
# Root Module - Providers Configuration
#------------------------------------------------------------------------------
# Configures Terraform and AWS provider settings.
#
# INDUSTRY CONTEXT:
# Provider configuration is critical for:
# - Version pinning (reproducible builds)
# - Authentication method
# - Default behaviors (tags, region)
# - Feature availability
#
# In CI/CD pipelines, authentication happens via:
# - OIDC (recommended - no long-lived credentials)
# - IAM roles (for EC2-based runners)
# - Environment variables (less secure fallback)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Terraform Configuration
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

#------------------------------------------------------------------------------
# AWS Provider
#------------------------------------------------------------------------------
# Primary provider configuration for all AWS resources.
#
# INDUSTRY CONTEXT:
# default_tags is a powerful feature:
# - Ensures ALL resources are tagged (compliance)
# - Reduces repetition in resource definitions
# - Enables cost allocation and tracking
# - Supports automated cleanup scripts
#
# Tags applied here merge with resource-level tags.
# Resource-level tags take precedence if there's a conflict.
#------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "infrastructure-as-code-pipeline"
    }
  }
}

#------------------------------------------------------------------------------
# Random Provider
#------------------------------------------------------------------------------
# Used for generating secure passwords and unique identifiers.
#
# INDUSTRY CONTEXT:
# The random provider is useful for:
# - Database passwords (random_password)
# - Unique resource names (random_id, random_pet)
# - Avoiding naming collisions in shared environments
#
# Random values are stored in state, so they persist across applies.
#------------------------------------------------------------------------------

provider "random" {
  # No configuration needed
}
