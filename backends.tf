#------------------------------------------------------------------------------
# Root Module - Backend Configuration
#------------------------------------------------------------------------------
# Configures remote state storage using S3 and DynamoDB.
#
# INDUSTRY CONTEXT:
# Remote state is essential for:
# - Team collaboration (shared state)
# - CI/CD pipelines (stateless runners)
# - State locking (prevent concurrent modifications)
# - State history (S3 versioning enables recovery)
#
# This backend uses the resources created in the Bootstrap phase:
# - S3 bucket: Stores the state file
# - DynamoDB table: Provides locking mechanism
#------------------------------------------------------------------------------

terraform {
  backend "s3" {
    #--------------------------------------------------------------------------
    # IMPORTANT: Update these values with your Bootstrap outputs
    #--------------------------------------------------------------------------
    # After running `terraform apply` in the Remote Backend Bootstrap folder,
    # copy the output values here:
    #
    # bucket         = "<your-state-bucket-name>"
    # dynamodb_table = "<your-dynamodb-table-name>"
    #--------------------------------------------------------------------------

    bucket         = "github-actions-terraform-deployment001"
    key            = "environments/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "iac-pipeline-terraform-locks"
    encrypt        = true

    #--------------------------------------------------------------------------
    # State File Organization
    #--------------------------------------------------------------------------
    # The "key" parameter defines where in the bucket the state is stored.
    #
    # INDUSTRY CONTEXT:
    # Common patterns for organizing state files:
    #
    # Pattern 1: By environment (using workspaces)
    #   key = "terraform.tfstate"
    #   Workspace creates: env:/dev/terraform.tfstate
    #                      env:/staging/terraform.tfstate
    #                      env:/prod/terraform.tfstate
    #
    # Pattern 2: By environment (separate keys)
    #   key = "environments/${var.environment}/terraform.tfstate"
    #   Creates: environments/dev/terraform.tfstate
    #            environments/staging/terraform.tfstate
    #
    # Pattern 3: By project and environment
    #   key = "projects/iac-pipeline/${var.environment}/terraform.tfstate"
    #
    # We use Pattern 1 with workspaces for this project.
    #--------------------------------------------------------------------------
  }
}

#------------------------------------------------------------------------------
# Workspace Strategy
#------------------------------------------------------------------------------
# Terraform workspaces allow multiple state files with the same configuration.
#
# INDUSTRY CONTEXT:
# Workspaces are ideal when:
# - Same infrastructure, different sizes (dev/staging/prod)
# - Same AWS account, isolated environments
# - Simple environment separation
#
# Workspaces are NOT ideal when:
# - Different AWS accounts per environment (use separate backends)
# - Significantly different infrastructure per environment
# - Complex multi-region deployments
#
# Usage:
#   terraform workspace new dev
#   terraform workspace new staging
#   terraform workspace new prod
#
#   terraform workspace select dev
#   terraform plan -var-file=environments/dev.tfvars
#
# State file locations in S3:
#   env:/dev/environments/terraform.tfstate
#   env:/staging/environments/terraform.tfstate
#   env:/prod/environments/terraform.tfstate
#------------------------------------------------------------------------------
