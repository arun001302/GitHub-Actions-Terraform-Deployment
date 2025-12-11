#------------------------------------------------------------------------------
# GitHub OIDC Variables
#------------------------------------------------------------------------------
# Only variables that are NEW for OIDC (not already in variables.tf)
#------------------------------------------------------------------------------

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo' (e.g., 'myuser/infrastructure-as-code-pipeline')"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$", var.github_repository))
    error_message = "GitHub repository must be in format 'owner/repo'."
  }
}

variable "github_actions_role_name" {
  description = "Name for the GitHub Actions IAM role"
  type        = string
  default     = "github-actions-terraform-role"
}