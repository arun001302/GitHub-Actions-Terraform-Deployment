#------------------------------------------------------------------------------
# GitHub Actions OIDC Authentication
#------------------------------------------------------------------------------
# Creates IAM resources for GitHub Actions to authenticate with AWS
# using OIDC (OpenID Connect) - no long-lived access keys needed!
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# GitHub OIDC Provider
#------------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

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

resource "aws_iam_role" "github_actions" {
  name        = var.github_actions_role_name
  description = "IAM role for GitHub Actions to deploy infrastructure via Terraform"

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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Name       = var.github_actions_role_name
    Purpose    = "GitHub Actions Terraform deployments"
    Repository = var.github_repository
    ManagedBy  = "terraform"
  }
}

#------------------------------------------------------------------------------
# IAM Policy for Terraform Operations
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
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:ListInstanceProfilesForRole",
          "iam:ListInstanceProfileTags",
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
          "secretsmanager:DeleteResourcePolicy",
          "secretsmanager:RestoreSecret"
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
          "kms:ListAliases",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # ELB/ALB Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "ELB"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # Auto Scaling Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "AutoScaling"
        Effect = "Allow"
        Action = [
          "autoscaling:*"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # SNS Permissions (for alarms)
      #------------------------------------------------------------------------
      {
        Sid    = "SNS"
        Effect = "Allow"
        Action = [
          "sns:*"
        ]
        Resource = "*"
      },

      #------------------------------------------------------------------------
      # SSM Permissions
      #------------------------------------------------------------------------
      {
        Sid    = "SSM"
        Effect = "Allow"
        Action = [
          "ssm:*"
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