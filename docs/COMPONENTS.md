# Component Reference

This document provides detailed technical reference for each Terraform component in the stack.

## Table of Contents

- [github-organization](#github-organization)
- [github-team](#github-team)
- [github-repository](#github-repository)
- [webhook-secret-manager](#webhook-secret-manager)

## github-organization

### Overview

Manages GitHub organization settings, member policies, and security configuration.

### Source

`./modules/github-organization`

### Provider Requirements

- `github` ~> 6.11

### Input Variables

#### `billing_email`
- **Type**: `string`
- **Required**: Yes
- **Description**: The billing email address for the organization

#### `company`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The company name for the organization

#### `blog`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The blog URL for the organization

#### `email`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The email address for the organization

#### `location`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The location for the organization

#### `name`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The display name for the organization

#### `description`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The description for the organization

#### `default_repository_permission`
- **Type**: `string`
- **Required**: No
- **Default**: `"read"`
- **Description**: The default permission for organization members
- **Allowed Values**: `read`, `write`, `admin`, `none`

#### `members_can_create_public_repositories`
- **Type**: `bool`
- **Required**: No
- **Default**: `false`
- **Description**: Whether organization members can create public repositories

#### `members_can_create_private_repositories`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Whether organization members can create private repositories

#### `dependabot_alerts_enabled_for_new_repositories`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Whether Dependabot alerts are enabled for new repositories

#### `secret_scanning_enabled_for_new_repositories`
- **Type**: `bool`
- **Required**: No
- **Default**: `false`
- **Description**: Whether secret scanning is enabled for new repositories

### Resources Created

- `github_organization_settings` - Organization configuration resource

### Output Variables

- `organization_id` - The ID of the GitHub organization
- `organization_name` - The name of the GitHub organization

### Example Configuration

```hcl
component "github-organization" {
  source = "./modules/github-organization"

  providers = {
    github = provider.github.main
  }

  inputs = {
    billing_email                                        = "billing@example.com"
    company                                              = "Example Company"
    name                                                 = "Example Organization"
    description                                          = "Example organization description"
    default_repository_permission                        = "read"
    members_can_create_public_repositories               = false
    members_can_create_private_repositories              = true
    dependabot_alerts_enabled_for_new_repositories       = true
    secret_scanning_enabled_for_new_repositories         = true
  }
}
```

## github-team

### Overview

Manages GitHub teams, team memberships, and hierarchical team relationships.

### Source

`./modules/github-team`

### Provider Requirements

- `github` ~> 6.11

### Input Variables

#### `name`
- **Type**: `string`
- **Required**: Yes
- **Description**: The name of the team

#### `description`
- **Type**: `string`
- **Required**: No
- **Default**: `""`
- **Description**: A description of the team

#### `privacy`
- **Type**: `string`
- **Required**: No
- **Default**: `"closed"`
- **Description**: The level of privacy for the team
- **Allowed Values**: `secret`, `closed`

#### `parent_team_id`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The ID of the parent team for nested teams

#### `ldap_dn`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: The LDAP Distinguished Name of the group

#### `members`
- **Type**: `map(string)`
- **Required**: No
- **Default**: `{}`
- **Description**: Map of GitHub usernames to their role (member or maintainer)
- **Allowed Values**: `member`, `maintainer`

### Resources Created

- `github_team` - Team resource
- `github_team_membership` - Team member assignments (one per member)

### Output Variables

- `team_id` - The ID of the team
- `team_node_id` - The Node ID of the team
- `team_slug` - The slug of the team
- `team_name` - The name of the team
- `team_members_count` - The number of members in the team

### Example Configuration

```hcl
component "github-teams" {
  source   = "./modules/github-team"
  for_each = var.github_teams

  providers = {
    github = provider.github.main
  }

  inputs = {
    name        = each.key
    description = each.value.description
    privacy     = each.value.privacy
    members     = each.value.members
  }
}
```

### Example Team Configuration

```hcl
github_teams = {
  "engineering" = {
    description = "Engineering Team"
    privacy     = "closed"
    members = {
      "alice.smith" = "maintainer"
      "bob.jones"   = "member"
      "carol.white" = "member"
    }
  }
  "devops" = {
    description = "DevOps Team"
    privacy     = "closed"
    members = {
      "dave.brown" = "maintainer"
      "eve.davis"  = "member"
    }
  }
}
```

## github-repository

### Overview

Comprehensive repository lifecycle management including creation, branch protection, access control, and webhook configuration.

### Source

`./modules/github-repository`

### Provider Requirements

- `github` ~> 6.11

### Input Variables

#### `name`
- **Type**: `string`
- **Required**: Yes
- **Description**: The name of the repository

#### `description`
- **Type**: `string`
- **Required**: No
- **Default**: `""`
- **Description**: A description of the repository

#### `visibility`
- **Type**: `string`
- **Required**: No
- **Default**: `"private"`
- **Description**: The visibility of the repository
- **Allowed Values**: `public`, `private`, `internal`

#### `has_issues`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Enable the GitHub Issues features on the repository

#### `has_projects`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Enable the GitHub Projects features on the repository

#### `has_wiki`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Enable the GitHub Wiki features on the repository

#### `topics`
- **Type**: `list(string)`
- **Required**: No
- **Default**: `[]`
- **Description**: The list of topics of the repository

#### `allow_squash_merge`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Set to true to allow squash merges

#### `allow_merge_commit`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Set to true to allow merge commits

#### `allow_rebase_merge`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Set to true to allow rebase merges

#### `delete_branch_on_merge`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Automatically delete head branch after a pull request is merged

#### `gitignore_template`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: Use the name of the gitignore template without the extension

#### `license_template`
- **Type**: `string`
- **Required**: No
- **Default**: `null`
- **Description**: Use the name of the license template without the extension

#### `branch_protection`
- **Type**: `map(object)`
- **Required**: No
- **Default**: `{}`
- **Description**: Branch protection rules configuration
- **Object Schema**:
  ```hcl
  {
    required_status_checks = optional(object({
      strict   = optional(bool)
      contexts = optional(list(string))
    }))
    required_pull_request_reviews = optional(object({
      dismiss_stale_reviews           = optional(bool)
      require_code_owner_reviews      = optional(bool)
      required_approving_review_count = optional(number)
    }))
    enforce_admins          = optional(bool)
    require_signed_commits  = optional(bool)
    required_linear_history = optional(bool)
  }
  ```

#### `team_permissions`
- **Type**: `map(string)`
- **Required**: No
- **Default**: `{}`
- **Description**: Map of team names to their permissions
- **Allowed Values**: `pull`, `triage`, `push`, `maintain`, `admin`

#### `team_ids`
- **Type**: `map(string)`
- **Required**: No
- **Default**: `{}`
- **Description**: Map of team names to their IDs (provided by component dependency)

#### `webhooks`
- **Type**: `map(object)`
- **Required**: No
- **Default**: `{}`
- **Description**: Repository webhooks configuration
- **Object Schema**:
  ```hcl
  {
    url           = string
    content_type  = optional(string)
    events        = list(string)
    active        = optional(bool)
    rotation_days = optional(number)
  }
  ```

#### `webhook_secrets`
- **Type**: `map(string)`
- **Required**: No
- **Default**: `{}`
- **Sensitive**: Yes
- **Description**: Map of webhook secrets (from webhook-secret-manager module)

#### `vulnerability_alerts`
- **Type**: `bool`
- **Required**: No
- **Default**: `true`
- **Description**: Set to true to enable security alerts for vulnerable dependencies

### Resources Created

- `github_repository` - Repository resource
- `github_branch_protection` - Branch protection rules (one per protected branch)
- `github_team_repository` - Team access assignments (one per team)
- `github_repository_webhook` - Webhook configurations (one per webhook)

### Output Variables

- `repository_id` - The ID of the repository
- `repository_node_id` - The Node ID of the repository
- `repository_name` - The name of the repository
- `repository_full_name` - The full name of the repository (organization/name)
- `repository_html_url` - URL to the repository on the web
- `repository_ssh_clone_url` - URL to clone the repository via SSH
- `repository_http_clone_url` - URL to clone the repository via HTTPS

### Example Configuration

```hcl
component "github-repositories" {
  source   = "./modules/github-repository"
  for_each = var.github_repositories

  providers = {
    github = provider.github.main
  }

  inputs = {
    name                   = each.key
    description            = each.value.description
    visibility             = each.value.visibility
    has_issues             = each.value.has_issues
    topics                 = each.value.topics
    branch_protection      = each.value.branch_protection
    team_permissions       = each.value.team_permissions
    webhooks               = each.value.webhooks
    team_ids               = { for k, v in component.github-teams : k => v.team_id }
    webhook_secrets        = component.webhook-secret-manager.webhook_secrets
  }
}
```

### Example Repository Configuration

```hcl
github_repositories = {
  "api-service" = {
    description = "Main API Service"
    visibility  = "private"
    has_issues  = true
    topics      = ["api", "backend", "nodejs"]
    
    gitignore_template = "Node"
    license_template   = "mit"
    
    allow_squash_merge     = true
    allow_merge_commit     = false
    delete_branch_on_merge = true
    
    branch_protection = {
      "main" = {
        required_status_checks = {
          strict   = true
          contexts = ["ci/test", "ci/lint"]
        }
        required_pull_request_reviews = {
          required_approving_review_count = 2
          require_code_owner_reviews      = true
        }
        require_signed_commits = true
      }
    }
    
    team_permissions = {
      "engineering" = "admin"
      "devops"      = "push"
    }
    
    webhooks = {
      "ci-webhook" = {
        url           = "https://ci.example.com/webhook"
        events        = ["push", "pull_request"]
        rotation_days = 30
      }
    }
  }
}
```

## webhook-secret-manager

### Overview

Manages automatic webhook secret generation, secure storage in GCP Secret Manager, and time-based rotation.

### Source

`./modules/webhook-secret-manager`

### Provider Requirements

- `google` ~> 7.24
- `random` ~> 3.6
- `time` ~> 0.12

### Input Variables

#### `gcp_project_name`
- **Type**: `string`
- **Required**: Yes
- **Description**: GCP project name for Secret Manager

#### `webhook_configs`
- **Type**: `map(object)`
- **Required**: Yes
- **Description**: Map of webhook configurations requiring secrets
- **Object Schema**:
  ```hcl
  {
    repository_name = string
    webhook_name    = string
    url             = string
    rotation_days   = number
  }
  ```

#### `secret_length`
- **Type**: `number`
- **Required**: No
- **Default**: `32`
- **Description**: Length of generated webhook secrets

### Resources Created

- `google_project_service.secretmanager` - Enables Secret Manager API
- `time_rotating.webhook_secret_rotation` - Rotation triggers (one per webhook)
- `random_password.webhook_secret` - Generated secrets (one per webhook)
- `google_secret_manager_secret.webhook_secret` - Secret storage (one per webhook)
- `google_secret_manager_secret_version.webhook_secret` - Secret versions (one per webhook)
- `google_secret_manager_secret.webhook_secret_metadata` - Metadata storage (one per webhook)
- `google_secret_manager_secret_version.webhook_secret_metadata` - Metadata versions (one per webhook)

### Output Variables

- `webhook_secrets` (sensitive) - Map of generated secrets
- `secret_ids` - Map of GCP Secret Manager secret IDs
- `secret_names` - Map of GCP Secret Manager secret full names
- `rotation_timestamps` - Map of rotation timestamps for tracking
- `metadata_secret_ids` - Map of metadata secret IDs

### Secret Naming Convention

**Webhook Secrets**: `github-webhook-{repository}-{webhook-name}`

**Metadata Secrets**: `github-webhook-{repository}-{webhook-name}-metadata`

### Secret Labels

All secrets include the following labels:
- `type`: `github-webhook`
- `repository`: Repository name
- `webhook`: Webhook name
- `managed_by`: `terraform`
- `rotation_days`: Rotation period

### Example Configuration

```hcl
component "webhook-secret-manager" {
  source = "./modules/webhook-secret-manager"

  providers = {
    google = provider.google.main
    random = provider.random.main
    time   = provider.time.main
  }

  inputs = {
    gcp_project_name = "my-gcp-project"
    
    webhook_configs = {
      "api-service-ci-webhook" = {
        repository_name = "api-service"
        webhook_name    = "ci-webhook"
        url             = "https://ci.example.com/webhook"
        rotation_days   = 30
      }
      "api-service-slack" = {
        repository_name = "api-service"
        webhook_name    = "slack"
        url             = "https://hooks.slack.com/..."
        rotation_days   = 180
      }
    }
  }
}
```

### Rotation Behavior

1. **Initial Creation**: Secret generated and stored
2. **Active Period**: Secret remains unchanged
3. **Rotation Trigger**: After N days, time_rotating resource expires
4. **New Generation**: New secret generated with updated keeper
5. **Storage**: New version created in Secret Manager
6. **Application**: GitHub webhook automatically updated

### Accessing Secrets

**Via Terraform Outputs**:
```bash
terraform output webhook_secret_ids
terraform output webhook_rotation_timestamps
```

**Via gcloud CLI**:
```bash
gcloud secrets versions access latest \
  --secret="github-webhook-api-service-ci-webhook" \
  --project=my-gcp-project
```

**Via GCP Console**:
1. Navigate to Secret Manager
2. Filter by label: `type=github-webhook`
3. Select secret to view versions and metadata

