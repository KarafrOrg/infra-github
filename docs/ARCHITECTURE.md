# Architecture Overview

This document provides a comprehensive overview of the GitHub infrastructure architecture managed by Terraform Stacks.

## Table of Contents

- [Stack Structure](#stack-structure)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [Security Model](#security-model)
- [Best Practices](#best-practices)

## Stack Structure

The infrastructure is organized using Terraform Stacks with a clear separation of concerns:

```
infra-github/
├── components.tfcomponent.hcl      # Component declarations
├── deployments.tfdeploy.hcl        # Deployment configurations
├── providers.tfcomponent.hcl       # Provider configurations
├── variables.tfcomponent.hcl       # Global variables
├── outputs.tfdeployment.hcl        # Output definitions
└── modules/                        # Terraform modules
    ├── github-organization/
    ├── github-repository/
    ├── github-team/
    └── webhook-secret-manager/
```

### Hierarchical Structure

```
Providers
    └── Variables
        └── Components
            ├── github-organization
            ├── github-teams
            ├── webhook-secret-manager
            └── github-repositories (depends on teams, secrets)
                └── Deployments
```

## Component Architecture

### 1. GitHub Organization Component

**Purpose**: Manages GitHub organization settings and member policies.

**Resources Created**:
- Organization settings
- Member permission policies
- Security configuration

**Key Features**:
- Organization profile configuration
- Member permission management
- Repository creation policies
- Security policy enforcement

**Configuration**:
```hcl
component "github-organization" {
  inputs = {
    billing_email = "billing@example.com"
    default_repository_permission = "read"
    members_can_create_private_repositories = true
  }
}
```

### 2. GitHub Team Component

**Purpose**: Manages GitHub teams and team memberships.

**Resources Created**:
- GitHub teams
- Team member assignments
- Team hierarchy relationships

**Key Features**:
- Team creation with privacy controls
- Member role assignment
- Nested team support
- LDAP integration capability

**Configuration**:
```hcl
component "github-teams" {
  inputs = {
    name        = "engineering"
    description = "Engineering Team"
    privacy     = "closed"
    members = {
      "user1" = "maintainer"
      "user2" = "member"
    }
  }
}
```

### 3. Webhook Secret Manager Component

**Purpose**: Manages automatic webhook secret generation, storage, and rotation.

**Resources Created**:
- Random password generation
- Time-based rotation triggers
- GCP Secret Manager secrets
- Secret versions with metadata

**Key Features**:
- Cryptographically secure secret generation
- Automated rotation based on time triggers
- Per-webhook rotation policies
- Secret metadata tracking

**Configuration**:
```hcl
component "webhook-secret-manager" {
  inputs = {
    gcp_project_name = "my-gcp-project"
    webhook_configs = {
      "repo-webhook" = {
        repository_name = "my-repo"
        webhook_name    = "ci-webhook"
        url             = "https://ci.example.com/webhook"
        rotation_days   = 30
      }
    }
  }
}
```

### 4. GitHub Repository Component

**Purpose**: Comprehensive GitHub repository lifecycle management.

**Resources Created**:
- GitHub repositories
- Branch protection rules
- Team repository access
- Repository webhooks
- Collaborator assignments

**Key Features**:
- Repository creation and configuration
- Branch protection policy enforcement
- Team-based access control
- Webhook integration with secret management
- Deploy key management

**Configuration**:
```hcl
component "github-repositories" {
  inputs = {
    name        = "api-service"
    description = "Main API Service"
    visibility  = "private"
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
```

## Data Flow

### Repository Creation Flow

```
1. Deployments → Variables
   ↓
2. Organization Component
   - Creates organization settings
   ↓
3. Team Components (parallel)
   - Create teams
   - Assign members
   ↓
4. Webhook Secret Manager Component
   - Generate secrets
   - Store in GCP Secret Manager
   - Create rotation triggers
   ↓
5. Repository Component
   - Create repositories
   - Configure branch protection
   - Assign team permissions
   - Configure webhooks with generated secrets
```

### Webhook Secret Rotation Flow

```
1. Time Rotating Resource
   - Monitors rotation period
   - Triggers after N days
   ↓
2. Random Password Resource
   - Generates new secret
   - Updates keeper value
   ↓
3. Secret Manager Secret Version
   - Creates new version
   - Stores new secret
   ↓
4. Repository Webhook
   - Automatically uses latest secret
   - Updates GitHub webhook configuration
```

### Component Dependency Chain

```
providers.tfcomponent.hcl
    ↓
variables.tfcomponent.hcl
    ↓
components.tfcomponent.hcl
    ├── github-organization (no dependencies)
    ├── github-teams (no dependencies)
    ├── webhook-secret-manager (no dependencies)
    └── github-repositories
        ├── depends_on: github-teams
        └── depends_on: webhook-secret-manager
    ↓
deployments.tfdeploy.hcl
    ↓
outputs.tfdeployment.hcl
```

## Security Model

### Authentication and Authorization

**GitHub Authentication**:
- Personal Access Token with limited scopes
- Stored securely in Terraform Cloud variable sets
- Ephemeral token handling (never persisted in state)

**GCP Authentication**:
- Workload Identity Federation
- Service account impersonation
- No static credentials required

### Secret Management

**Secret Generation**:
- Cryptographically secure random generation
- Configurable length (default: 32 characters)
- Unique secret per webhook

**Secret Storage**:
- GCP Secret Manager encrypted storage
- Version history maintained
- IAM-based access control

**Secret Rotation**:
- Time-based automatic rotation
- Per-webhook rotation policies
- Zero-downtime rotation process

### Access Control

**Team-Based Permissions**:
- Centralized team management
- Hierarchical permission structure
- Principle of least privilege

**Repository Access Levels**:
- `pull`: Read-only access
- `triage`: Issue management
- `push`: Write access
- `maintain`: Repository management
- `admin`: Full administrative control

### Branch Protection

**Required Reviews**:
- Configurable approval count
- Code owner review requirement
- Stale review dismissal

**Status Checks**:
- Required CI/CD checks
- Strict context matching
- Signed commit enforcement

## Best Practices

### Component Design

**Single Responsibility**:
- Each component manages one infrastructure concern
- Clear input/output boundaries
- Minimal cross-component coupling

**Explicit Dependencies**:
- Use `depends_on` for ordering
- Avoid implicit dependencies
- Document dependency rationale

**Idempotency**:
- Components produce same result on repeat application
- No side effects from multiple runs
- Proper state management

### Variable Management

**Organization**:
- Group related variables together
- Use descriptive names
- Provide comprehensive descriptions

**Defaults**:
- Sensible defaults for optional variables
- Security-first default values
- Document default rationale

**Validation**:
- Input validation rules
- Type constraints
- Value range checks

### Secret Management

**Rotation Policies**:
- Match rotation frequency to risk level
- High-security: 7-14 days
- Standard: 30-90 days
- Low-risk: 90-365 days

**Monitoring**:
- Track rotation timestamps
- Alert on rotation failures
- Audit secret access

**Storage**:
- Never commit secrets to version control
- Use ephemeral variables
- Leverage Secret Manager versioning

### Repository Configuration

**Branch Protection**:
- Always protect production branches
- Require code review
- Enforce status checks

**Merge Strategies**:
- Prefer squash merging for clean history
- Disable merge commits
- Enable automatic branch deletion

**Access Control**:
- Use teams over individual access
- Regular access audits
- Document permission rationale

### Deployment Practices

**Change Management**:
- Review all changes before apply
- Test in non-production first
- Maintain change documentation

**State Management**:
- Use remote state backend
- Enable state locking
- Regular state backups

**Monitoring**:
- Track resource changes
- Monitor apply failures
- Alert on drift detection

## Infrastructure Patterns

### Multi-Environment Support

While this stack uses a single production deployment, multi-environment support can be achieved through:

**Separate Deployments**:
```hcl
deployment "development" { }
deployment "staging" { }
deployment "production" { }
```

**Environment-Specific Variables**:
- Different rotation periods per environment
- Varying branch protection rules
- Environment-specific team structures

### Disaster Recovery

**State Recovery**:
- Regular state backups
- Version control for configuration
- Import capability for existing resources

**Secret Recovery**:
- Secret Manager version history
- Metadata tracking for troubleshooting
- Audit logs for access tracking

### Scalability Considerations

**Component Scaling**:
- For-each loops for multiple instances
- Dynamic resource generation
- Efficient state management

**Performance**:
- Parallel resource creation
- Minimal API calls
- Optimized dependency chains

