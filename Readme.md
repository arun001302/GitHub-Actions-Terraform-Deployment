# Infrastructure as Code Pipeline with Terraform & GitHub Actions

[![Terraform CI/CD Pipeline](https://github.com/arun001302/GitHub-Actions-Terraform-Deployment/actions/workflows/terraform.yml/badge.svg)](https://github.com/arun001302/GitHub-Actions-Terraform-Deployment/actions/workflows/terraform.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple.svg)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-orange.svg)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-ready Infrastructure as Code (IaC) pipeline demonstrating enterprise-grade AWS infrastructure deployment using Terraform and GitHub Actions with OIDC authentication.

---

## 🎯 Project Overview

This project demonstrates how to build a complete CI/CD pipeline for infrastructure deployment, following industry best practices used by DevOps teams at scale. It provisions a multi-tier AWS architecture with automated validation, security scanning, and deployment workflows.

### What This Project Demonstrates

- **Infrastructure as Code** - All infrastructure defined in Terraform
- **GitOps Workflow** - Infrastructure changes through Pull Requests
- **Automated CI/CD** - GitHub Actions pipeline with multiple stages
- **Security-First Design** - OIDC authentication, no long-lived credentials
- **Multi-Environment Support** - Dev, Staging, and Production configurations
- **Modular Architecture** - Reusable Terraform modules

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                       │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                              VPC                                        │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────┐    ┌─────────────────────────┐           │ │
│  │  │    Public Subnets       │    │    Private Subnets      │           │ │
│  │  │  ┌─────────────────┐    │    │  ┌─────────────────┐    │           │ │
│  │  │  │  NAT Gateway    │    │    │  │   EC2 Instance  │    │           │ │
│  │  │  └─────────────────┘    │    │  │   (App Server)  │    │           │ │
│  │  │                         │    │  └─────────────────┘    │           │ │
│  │  │  ┌─────────────────┐    │    │                         │           │ │
│  │  │  │ Internet Gateway│    │    │  ┌─────────────────┐    │           │ │
│  │  │  └─────────────────┘    │    │  │   RDS PostgreSQL│    │           │ │
│  │  │                         │    │  │   (Database)    │    │           │ │
│  │  └─────────────────────────┘    │  └─────────────────┘    │           │ │
│  │                                  └─────────────────────────┘           │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│  │ Security Groups │  │   IAM Roles     │  │ Secrets Manager │             │
│  │ (ALB/App/RDS)   │  │ (EC2/SSM)       │  │ (DB Credentials)│             │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline automates the entire infrastructure lifecycle:

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Format  │──▶│ Validate │──▶│ Security │──▶│   Plan   │──▶│  Apply   │
│  Check   │   │          │   │   Scan   │   │          │   │          │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
     │              │              │              │              │
     ▼              ▼              ▼              ▼              ▼
  terraform     terraform      TFLint +      terraform      terraform
    fmt         validate       Checkov         plan          apply
```

### Pipeline Stages

| Stage | Tool | Purpose |
|-------|------|---------|
| **Format** | `terraform fmt` | Ensures consistent code style |
| **Validate** | `terraform validate` | Checks syntax and configuration |
| **Security** | TFLint + Checkov | Scans for misconfigurations and vulnerabilities |
| **Plan** | `terraform plan` | Previews infrastructure changes |
| **Apply** | `terraform apply` | Deploys infrastructure (main branch only) |

---

## 🔐 Security Features

### OIDC Authentication (No Static Credentials)

This project uses **OpenID Connect (OIDC)** for GitHub Actions to authenticate with AWS - no access keys stored anywhere.

```
GitHub Actions                    AWS
     │                             │
     │  1. Request OIDC Token      │
     │────────────────────────────▶│
     │                             │
     │  2. Validate Token          │
     │◀────────────────────────────│
     │                             │
     │  3. Issue Temporary Creds   │
     │◀────────────────────────────│
     │     (Valid 15 min)          │
```

### Additional Security Measures

- ✅ **No hardcoded secrets** - All credentials in AWS Secrets Manager
- ✅ **Encrypted storage** - RDS and EBS encryption enabled
- ✅ **Private subnets** - Database and app servers not publicly accessible
- ✅ **Security groups** - Layered network access control
- ✅ **IMDSv2 required** - Protection against SSRF attacks
- ✅ **SSM Session Manager** - No SSH keys needed for instance access

---

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       ├── terraform.yml           # Main CI/CD pipeline
│       └── terraform-destroy.yml   # Destroy workflow (manual)
│
├── modules/
│   ├── networking/                 # VPC, Subnets, Gateways
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── security/                   # Security Groups, IAM Roles
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/                    # EC2, Launch Templates
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── database/                   # RDS, Secrets Manager
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   ├── dev.tfvars                  # Development configuration
│   ├── staging.tfvars              # Staging configuration
│   └── prod.tfvars                 # Production configuration
│
├── Remote Backend Bootstrap/       # S3 + DynamoDB for state
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── github-oidc.tf              # OIDC provider and IAM role
│   └── github-oidc-variables.tf
│
├── main.tf                         # Root module composition
├── variables.tf                    # Input variables
├── outputs.tf                      # Output values
├── providers.tf                    # Provider configuration
├── backend.tf                      # Remote state configuration
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- GitHub Account
- Terraform >= 1.5.0
- AWS CLI configured locally

### Step 1: Bootstrap Remote Backend

```bash
cd "Remote Backend Bootstrap"
terraform init
terraform apply
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- GitHub OIDC provider
- IAM role for GitHub Actions

### Step 2: Configure GitHub Secrets

Add the following secret to your GitHub repository:

| Secret Name | Value |
|-------------|-------|
| `AWS_ROLE_ARN` | ARN from bootstrap output |

### Step 3: Push and Deploy

```bash
git add .
git commit -m "Initial infrastructure deployment"
git push origin main
```

The pipeline will automatically:
1. Validate your Terraform code
2. Run security scans
3. Create an execution plan
4. Deploy to AWS

---

## 🌍 Multi-Environment Configuration

| Environment | Instance Type | RDS Class | Multi-AZ | NAT Gateway |
|-------------|---------------|-----------|----------|-------------|
| **Dev** | t3.micro | db.t3.micro | No | No |
| **Staging** | t3.small | db.t3.small | No | Yes |
| **Prod** | t3.medium | db.t3.medium | Yes | Yes |

Deploy to different environments:

```bash
# Via GitHub Actions (manual trigger)
# Select environment: dev, staging, or prod

# Or locally:
terraform workspace select dev
terraform apply -var-file=environments/dev.tfvars
```

---

## 💰 Cost Estimation

| Environment | Monthly Cost (Approx.) |
|-------------|------------------------|
| Dev | ~$15-25 |
| Staging | ~$80-120 |
| Prod | ~$250-400 |

*Costs vary by region and usage. Destroy non-production environments when not in use.*

---

## 🗑️ Destroying Infrastructure

A separate destroy workflow is provided for safely tearing down environments:

1. Go to **Actions** → **Terraform Destroy**
2. Click **Run workflow**
3. Select the environment
4. Type `destroy` to confirm
5. Click **Run workflow**

---

## 🛠️ Technologies Used

| Technology | Purpose |
|------------|---------|
| **Terraform** | Infrastructure as Code |
| **GitHub Actions** | CI/CD Pipeline |
| **AWS** | Cloud Provider |
| **OIDC** | Secure Authentication |
| **TFLint** | Terraform Linting |
| **Checkov** | Security Scanning |

---

## 📚 Key Learnings

This project demonstrates proficiency in:

- **Infrastructure as Code** - Writing maintainable, modular Terraform
- **CI/CD Pipelines** - Automated testing and deployment workflows
- **AWS Architecture** - Multi-tier, secure cloud infrastructure
- **Security Best Practices** - OIDC, encryption, least privilege
- **GitOps** - Infrastructure changes through version control
- **DevOps Practices** - Automation, monitoring, documentation

---

## 🔗 Related Projects

- [3-Tier ECS Graviton Deployment](https://github.com/arun001302/3-Tier-ECS-Graviton-Deployment) - Containerized WordPress on AWS ECS with Graviton processors

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Arun**

- GitHub: [@arun001302](https://github.com/arun001302)

---

*Built as part of an AWS Cloud Engineering portfolio demonstrating enterprise-grade DevOps practices.*
