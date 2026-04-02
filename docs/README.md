# infra-github

Terraform Stacks configuration for managing GitHub organization, teams, and repositories.

## Quick Start

1. Configure Terraform Cloud with variable set containing GitHub token
2. Update `deployments.tfdeploy.hcl` with organization details
3. Run `terraform init && terraform apply`

See [Quick Start Guide](./docs/QUICK_START.md) for detailed instructions.

## Features

- Organization Management: Configure org-wide settings and security policies
- Team Management: Create teams with members and roles
- Repository Management: Full repository lifecycle with branch protection
- Access Control: Team-based repository permissions
- Webhooks: Configure repository webhooks for CI/CD
- Webhook Secret Management: Auto-generated secrets stored in GCP Secret Manager with automatic rotation
- Security: Dependabot, secret scanning, vulnerability alerts

## Structure

```
.
├── components.tfcomponent.hcl     # Component definitions
├── deployments.tfdeploy.hcl       # Deployment configurations
├── providers.tfcomponent.hcl      # Provider setup
├── variables.tfcomponent.hcl      # Variable definitions
├── outputs.tfdeployment.hcl       # Outputs
└── modules/                       # Reusable modules
    ├── github-organization/
    ├── github-repository/
    ├── github-team/
    └── webhook-secret-manager/    # Webhook secret generation & rotation
```

## Prerequisites

- Terraform >= 1.10.0 with Stacks support
- GitHub token with `admin:org` and `repo` scopes
- Terraform Cloud workspace (for variable storage)
- GCP Project with Secret Manager API enabled (for webhook secret management)

## Documentation

- [Complete Documentation](./docs/README.md) - Full feature documentation
- [Quick Start Guide](./docs/QUICK_START.md) - Get started in 5 minutes
- [Architecture Overview](./docs/ARCHITECTURE.md) - System architecture and design
- [Component Reference](./docs/COMPONENTS.md) - Detailed component documentation
- [Deployment Guide](./docs/DEPLOYMENT.md) - Deployment procedures and operations
- [Webhook Secret Management](./docs/WEBHOOK_SECRETS.md) - Auto-generated & rotated webhook secrets
- [Configuration Examples](./docs/EXAMPLES.md) - Real-world examples

## Usage Example

```hcl
# In deployments.tfdeploy.hcl
deployment "production" {
  inputs = {
    github_organization = "my-org"
    
    github_teams = {
      "engineering" = {
        description = "Engineering Team"
        members = {
          "user1" = "maintainer"
          "user2" = "member"
        }
      }
    }
    
    github_repositories = {
      "my-api" = {
        description = "My API Service"
        visibility  = "private"
        topics      = ["api", "backend"]
        
        branch_protection = {
          "main" = {
            required_pull_request_reviews = {
              required_approving_review_count = 2
            }
          }
        }
        
        team_permissions = {
          "engineering" = "admin"
        }
      }
    }
  }
}
```

## Common Tasks

### Add a Team
Edit `deployments.tfdeploy.hcl`:
```hcl
github_teams = {
  "new-team" = {
    description = "New Team"
    members = {
      "username" = "maintainer"
    }
  }
}
```

### Add a Repository
```hcl
github_repositories = {
  "new-repo" = {
    description = "New Repository"
    visibility  = "private"
    team_permissions = {
      "new-team" = "admin"
    }
  }
}
```
