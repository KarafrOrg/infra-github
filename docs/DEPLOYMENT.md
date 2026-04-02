# Deployment Guide

This document provides comprehensive deployment instructions, operational procedures, and troubleshooting guidance.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Authentication Setup](#authentication-setup)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Deployment Workflow](#deployment-workflow)
- [Troubleshooting](#troubleshooting)
- [Operations](#operations)

## Prerequisites

### Software Requirements

- Terraform 1.10.0 or higher with Stacks support
- gcloud CLI (optional, for Secret Manager operations)
- git for version control

### GitHub Requirements

**Organization Access**:
- Administrative access to GitHub organization
- Permission to create Personal Access Tokens or GitHub Apps

**Required Token Scopes**:
| Scope | Purpose |
|-------|---------|
| `admin:org` | Organization and team management |
| `repo` | Repository management |
| `delete_repo` | Repository deletion (optional) |

### GCP Requirements

**Project Setup**:
- GCP project with billing enabled
- Secret Manager API enabled
- Appropriate IAM permissions

**Required APIs**:
```bash
gcloud services enable secretmanager.googleapis.com --project=PROJECT_ID
gcloud services enable serviceusage.googleapis.com --project=PROJECT_ID
```

**Service Account**:
- Service account with Secret Manager permissions
- Workload Identity Federation configured (for Terraform Cloud)

**IAM Roles**:
- `roles/secretmanager.admin` - Secret Manager administration
- `roles/iam.workloadIdentityUser` - Workload Identity authentication

### Terraform Cloud Requirements

**Workspace Configuration**:
- Terraform Cloud workspace created
- Remote state backend configured
- Variable sets configured

**Variable Set Requirements**:
- Name: `infra-github-variables`
- Category: `terraform`
- Variables: `github_token`, `gcp_service_account_email`

## Authentication Setup

### GitHub Token Creation

1. Navigate to GitHub Settings
2. Select Developer settings → Personal access tokens → Tokens (classic)
3. Click "Generate new token (classic)"
4. Configure token:
   - **Name**: `terraform-github-management`
   - **Expiration**: Set appropriate expiration
   - **Scopes**: Select `admin:org`, `repo`
5. Generate token and securely store value

### Terraform Cloud Configuration

**Create Variable Set**:
```bash
# Via Terraform Cloud UI
1. Navigate to organization settings
2. Select "Variable sets"
3. Create new variable set: "infra-github-variables"
4. Add variables with appropriate values
```

**Required Variables**:
- `github_token` (sensitive, ephemeral)
- `gcp_service_account_email` (sensitive, ephemeral)

### GCP Workload Identity Federation

**Configure Identity Pool**:
```bash
# Create workload identity pool
gcloud iam workload-identity-pools create terraform-cloud \
  --location="global" \
  --description="Terraform Cloud Workload Identity Pool"

# Create provider
gcloud iam workload-identity-pools providers create-oidc terraform-cloud \
  --location="global" \
  --workload-identity-pool="terraform-cloud" \
  --issuer-uri="https://app.terraform.io" \
  --attribute-mapping="google.subject=assertion.sub"

# Grant permissions to service account
gcloud iam service-accounts add-iam-policy-binding \
  SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/terraform-cloud/*"
```

## Step-by-Step Deployment

### 1. Repository Setup

```bash
# Clone repository
git clone https://github.com/your-org/infra-github.git
cd infra-github

# Verify structure
ls -la
```

Expected structure:
```
components.tfcomponent.hcl
deployments.tfdeploy.hcl
providers.tfcomponent.hcl
variables.tfcomponent.hcl
outputs.tfdeployment.hcl
modules/
docs/
```

### 2. Configuration Customization

**Update Organization Settings**:

Edit `deployments.tfdeploy.hcl`:
```hcl
deployment "production" {
  inputs = {
    github_organization = "your-organization-name"
    billing_email       = "billing@your-domain.com"
    company             = "Your Company Name"
    
    # Update GCP configuration
    gcp_project_name = "your-gcp-project-id"
    gcp_region       = "us-central1"
  }
}
```

**Configure Teams**:
```hcl
github_teams = {
  "engineering" = {
    description = "Engineering Team"
    privacy     = "closed"
    members = {
      "user1" = "maintainer"
      "user2" = "member"
    }
  }
}
```

**Configure Repositories**:
```hcl
github_repositories = {
  "infrastructure" = {
    description = "Infrastructure as Code"
    visibility  = "private"
    topics      = ["terraform", "infrastructure"]
    
    team_permissions = {
      "engineering" = "admin"
    }
  }
}
```

### 3. Initialization

```bash
# Initialize Terraform
terraform init

# Verify providers
terraform providers
```

Expected output:
```
Providers required by configuration:
├── provider[registry.terraform.io/integrations/github] ~> 6.11
├── provider[registry.terraform.io/hashicorp/google] ~> 7.24
├── provider[registry.terraform.io/hashicorp/random] ~> 3.6
└── provider[registry.terraform.io/hashicorp/time] ~> 0.12
```

### 4. Planning

```bash
# Generate execution plan
terraform plan -out=tfplan

# Review plan output carefully
# Verify all resources to be created
# Check for unexpected changes
```

Review checklist:
- Organization settings match requirements
- Teams configured correctly
- Repositories have appropriate settings
- Branch protection rules are correct
- Webhook secrets will be generated
- Team permissions are accurate

### 5. Application

```bash
# Apply configuration
terraform apply tfplan

# Monitor apply progress
# Review created resources
```

Expected process:
1. Organization settings created
2. Teams created
3. Webhook secrets generated and stored
4. Repositories created
5. Branch protection applied
6. Team permissions assigned
7. Webhooks configured

### 6. Verification

**Verify Organization**:
```bash
# Check organization settings in GitHub UI
# Navigate to: https://github.com/organizations/YOUR_ORG/settings/profile
```

**Verify Teams**:
```bash
# Check teams in GitHub UI
# Navigate to: https://github.com/orgs/YOUR_ORG/teams
```

**Verify Repositories**:
```bash
# Check repositories in GitHub UI
# Verify branch protection on protected branches
# Verify team access in repository settings
```

**Verify Secrets**:
```bash
# List secrets in GCP Secret Manager
gcloud secrets list \
  --filter="labels.type=github-webhook" \
  --project=YOUR_PROJECT_ID

# View secret metadata
gcloud secrets versions access latest \
  --secret="github-webhook-REPO-WEBHOOK-metadata" \
  --project=YOUR_PROJECT_ID
```

### 7. Outputs

```bash
# View outputs
terraform output

# View specific outputs
terraform output organization_id
terraform output teams
terraform output repositories
terraform output webhook_secret_ids
```

## Deployment Workflow

### Standard Workflow

```
1. Create feature branch
   git checkout -b update-repositories

2. Make configuration changes
   vim deployments.tfdeploy.hcl

3. Validate syntax
   terraform fmt -check
   terraform validate

4. Create plan
   terraform plan -out=tfplan

5. Review plan
   Review all proposed changes

6. Apply changes
   terraform apply tfplan

7. Verify deployment
   Check GitHub and GCP resources

8. Commit changes
   git add .
   git commit -m "Add new repository configuration"
   git push origin update-repositories

9. Create pull request
   Review changes with team
   Merge to main branch
```

### Emergency Changes

For urgent changes requiring immediate deployment:

```bash
# 1. Create emergency branch
git checkout -b emergency/fix-branch-protection

# 2. Make minimal required changes
vim deployments.tfdeploy.hcl

# 3. Quick validation
terraform validate

# 4. Apply immediately
terraform apply -auto-approve

# 5. Verify fix
# Check affected resources

# 6. Document change
# Create issue tracking emergency change

# 7. Create pull request for review
# Post-deployment review and documentation
```

## Troubleshooting

### Authentication Errors

**Problem**: GitHub authentication failure
```
Error: GET https://api.github.com/user: 401 Bad credentials
```

**Resolution**:
1. Verify token is set in Terraform Cloud variable set
2. Check token expiration date
3. Verify token has required scopes
4. Regenerate token if necessary

**Problem**: GCP authentication failure
```
Error: google: could not find default credentials
```

**Resolution**:
1. Verify Workload Identity Federation configuration
2. Check service account permissions
3. Verify identity token audience matches configuration
4. Review service account IAM bindings

### Resource Conflicts

**Problem**: Team already exists
```
Error: error creating GitHub Team: Team name already taken
```

**Resolution**:
```bash
# Import existing team
terraform import 'component.github-teams["team-name"].github_team.team' existing-team-slug

# Re-run apply
terraform apply
```

**Problem**: Repository already exists
```
Error: POST https://api.github.com/orgs/ORG/repos: 422 name already exists
```

**Resolution**:
```bash
# Import existing repository
terraform import 'component.github-repositories["repo-name"].github_repository.repository' existing-repo-name

# Re-run apply
terraform apply
```

**Problem**: Branch protection conflict
```
Error: error creating GitHub Branch Protection: Branch protection already exists
```

**Resolution**:
```bash
# Remove existing protection manually via GitHub UI
# Or import existing protection
terraform import 'component.github-repositories["repo"].github_branch_protection.protection["main"]' repo-name:main

# Re-run apply
terraform apply
```

### State Management Issues

**Problem**: State lock error
```
Error: Error acquiring the state lock
```

**Resolution**:
1. Wait for concurrent operation to complete
2. If stuck, forcibly unlock (use with caution):
```bash
terraform force-unlock LOCK_ID
```

**Problem**: State drift detected
```
Error: Resource has been modified outside of Terraform
```

**Resolution**:
```bash
# Refresh state
terraform refresh

# Review changes
terraform plan

# Apply to reconcile
terraform apply
```

### Webhook Secret Issues

**Problem**: Secret Manager API not enabled
```
Error: Error 403: Secret Manager API has not been used
```

**Resolution**:
```bash
# Enable API
gcloud services enable secretmanager.googleapis.com --project=PROJECT_ID

# Re-run apply
terraform apply
```

**Problem**: Insufficient permissions for Secret Manager
```
Error: Permission 'secretmanager.secrets.create' denied
```

**Resolution**:
1. Grant required IAM role to service account:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"
```

### Component Dependency Issues

**Problem**: Team ID not found
```
Error: Invalid index: The given key does not identify an element in this collection value
```

**Resolution**:
- Verify teams are created before repositories
- Check `depends_on` in components.tfcomponent.hcl
- Ensure team names match between configuration and references

## Operations

### Adding a New Team

1. Edit `deployments.tfdeploy.hcl`:
```hcl
github_teams = {
  "new-team" = {
    description = "New Team Description"
    privacy     = "closed"
    members = {
      "username" = "maintainer"
    }
  }
}
```

2. Apply changes:
```bash
terraform plan
terraform apply
```

### Adding a New Repository

1. Edit `deployments.tfdeploy.hcl`:
```hcl
github_repositories = {
  "new-repo" = {
    description = "New Repository"
    visibility  = "private"
    
    team_permissions = {
      "engineering" = "admin"
    }
    
    branch_protection = {
      "main" = {
        required_pull_request_reviews = {
          required_approving_review_count = 1
        }
      }
    }
  }
}
```

2. Apply changes:
```bash
terraform plan
terraform apply
```

### Modifying Branch Protection

1. Update branch protection rules in `deployments.tfdeploy.hcl`
2. Plan and apply changes
3. Verify in GitHub UI

### Rotating Webhook Secrets Manually

```bash
# Taint the rotation resource
terraform taint 'component.webhook-secret-manager.time_rotating.webhook_secret_rotation["repo-webhook"]'

# Apply to regenerate
terraform apply
```

### Updating Team Memberships

1. Edit team members in `deployments.tfdeploy.hcl`
2. Plan and review changes
3. Apply to update memberships

### Destroying Resources

**Destroy specific repository**:
```bash
terraform destroy -target='component.github-repositories["repo-name"]'
```

**Destroy all resources** (use with extreme caution):
```bash
terraform destroy
```

### State Operations

**View state**:
```bash
terraform state list
```

**Show specific resource**:
```bash
terraform state show 'component.github-teams["team-name"].github_team.team'
```

**Remove resource from state**:
```bash
terraform state rm 'component.github-teams["team-name"]'
```

### Backup and Recovery

**Export state**:
```bash
terraform state pull > terraform.tfstate.backup
```

**Import existing resource**:
```bash
terraform import 'component.github-repositories["repo"].github_repository.repository' repo-name
```

