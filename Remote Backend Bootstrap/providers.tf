#------------------------------------------------------------------------------
# Bootstrap Providers Configuration
#------------------------------------------------------------------------------
# This file defines the required providers and their version constraints.
# 
# INDUSTRY CONTEXT:
# Version pinning is critical in production environments. Without it:
# - A new provider version could introduce breaking changes
# - Your CI/CD pipeline might use different versions than local development
# - Reproducible builds become impossible
#
# The "~>" operator allows only the rightmost version component to increment.
# Example: "~> 5.0" allows 5.1, 5.99 but NOT 6.0
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# AWS Provider Configuration
#------------------------------------------------------------------------------
# The region is parameterized via variables for flexibility.
# Default tags ensure every resource created by this configuration
# is tagged for cost tracking and ownership identification.
#
# INDUSTRY CONTEXT:
# Default tags at the provider level are an enterprise best practice:
# - Ensures NO resource escapes tagging (compliance requirement)
# - Simplifies cost allocation and chargeback
# - Enables automated cleanup of resources by project/environment
#------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Purpose     = "terraform-state-backend"
    }
  }
}