#------------------------------------------------------------------------------
# GitHub Actions OIDC Authentication
#------------------------------------------------------------------------------
# Creates IAM resources for GitHub Actions to authenticate with AWS
# using OIDC (OpenID Connect) - no long-lived access keys needed!
#
# INDUSTRY CONTEXT:
# OIDC is the recommended way to authenticate CI/CD with AWS because:
# - No secrets to rotate or manage
# - Credentials are temporary (minutes, not forever)
# - Can restrict access by repo, branch, environment
# - Full audit trail in CloudTrail
#
# SECURITY:
# The trust policy is critical - it defines WHO can assume this role.
# We restrict it to:
# - Specific GitHub repository
# - Specific branches (optional)
# - Specific environments (optional)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# GitHub OIDC Provider
#------------------------------------------------------------------------------
# This tells AWS to trust tokens issued by GitHub.
# You only need ONE provider per AWS account, regardless of how many repos.
#
# IMPORTANT: If you already have a GitHub OIDC provider in your account,
# you can comment out this resource and reference the existing one.
#------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint
  # This is GitHub's certificate thumbprint - it's public and stable
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = {
    Name        = "github-actions-oidc"
    Description = "OIDC provider for GitHub Actions"
    ManagedBy   = "terraform"
  }
}

#------------------------------------------------------------------------------
# IAM Role for GitHub Actions
#------------------------------------------------------------------------------
# This role is what GitHub Actions assumes to get AWS credentials.
#------------------------------------------------------------------------------

resource "aws_iam_role" "github_actions" {
  name        = var.github_actions_role_name
  description = "IAM role for GitHub Actions to deploy infrastructure via Terraform"

  # Trust policy - defines WHO can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to specific repository
            # Format: repo:OWNER/REPO:*
            # Examples:
            #   "repo:myuser/myrepo:*"                    - Any branch/event
            #   "repo:myuser/myrepo:ref:refs/heads/main"  - Only main branch
            #   "repo:myuser/myrepo:environment:prod"     - Only prod environment
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = var.github_actions_role_name
    Purpose     = "GitHub Actions Terraform deployments"
    Repository  = var.github_repository
    ManagedBy   = "terraform"
  }
}

#------------------------------------------------------------------------------
# IAM Policy for Terraform Operations
#------------------------------------------------------------------------------
# Defines WHAT the GitHub Actions role can do in AWS.
#
# INDUSTRY CONTEXT:
# This is a broad policy suitable for Terraform deployments.
# In production, you might want to:
# - Restrict to specific resource types
# - Restrict to specific resource name patterns
# - Use permission boundaries
# - Separate read-only (plan) from write (apply) roles
#------------------------------------------------------------------------------

resource "aws_iam_policy" "github_actions_terraform" {
  name        = "${var.github_actions_role_name}-policy"
  description = "Policy for GitHub Actions to run Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      #------------------------------------------------------------------------
      # Terraform State Access
      #------------------------------------------------------------------------
      {
        Sid    = "TerraformStateS3"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*"
        ]
      },
      {
        Sid    = "TerraformStateDynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
      },

      #------------------------------------------------------------------------
      # EC2 and VPC Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "EC2Full"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # RDS Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "RDSFull"
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # IAM Permissions (for creating roles, instance profiles)
      #------------------------------------------------------------------------
      {
        Sid    = "IAMManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # Secrets Manager Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:DeleteResourcePolicy"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # CloudWatch Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "CloudWatch"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # KMS Permissions (for encryption)
      #------------------------------------------------------------------------
      {
        Sid    = "KMS"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:EnableKey",
          "kms:DisableKey",
          "kms:GetKeyPolicy",
          "kms:GetKeyRotationStatus",
          "kms:ListResourceTags",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:ListAliases"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "${var.github_actions_role_name}-policy"
    ManagedBy = "terraform"
  }
}

#------------------------------------------------------------------------------
# Attach Policy to Role
#------------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_terraform.arn
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role - add this to GitHub Secrets as AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_setup_instructions" {
  description = "Instructions for configuring GitHub Actions"
  value       = <<-EOT

    ============================================================
    GITHUB ACTIONS SETUP INSTRUCTIONS
    ============================================================

    1. Go to your GitHub repository:
       https://github.com/${var.github_repository}/settings/secrets/actions

    2. Click "New repository secret"

    3. Add the following secret:
       Name:  AWS_ROLE_ARN
       Value: ${aws_iam_role.github_actions.arn}

    4. Create GitHub Environments (optional but recommended):
       https://github.com/${var.github_repository}/settings/environments

       - Create "dev" environment (no protection rules)
       - Create "staging" environment (optional: require reviewers)
       - Create "prod" environment (require reviewers)

    5. Your GitHub Actions workflow can now authenticate with AWS!

    ============================================================
  EOT
}