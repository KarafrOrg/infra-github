variable "github_token" {
  description = "GitHub personal access token or GitHub App token"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "github_organization" {
  description = "GitHub organization name"
  type        = string
}

# GCP Configuration
variable "gcp_project_name" {
  description = "GCP project name for Secret Manager"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_identity_token" {
  type        = string
  ephemeral   = true
  description = "JWT identity token for GCP authentication"
  sensitive   = true
}

variable "gcp_audience" {
  type        = string
  description = "The fully qualified GCP identity provider name"
  sensitive   = true
  ephemeral   = true
}

variable "gcp_service_account_email" {
  type        = string
  sensitive   = true
  ephemeral   = true
  description = "GCP service account email for Terraform"
}

# Webhook secret rotation configuration
variable "webhook_secret_rotation_days" {
  description = "Number of days before webhook secrets are rotated"
  type        = number
  default     = 90
}

# Organization settings variables
variable "billing_email" {
  description = "The billing email address for the organization"
  type        = string
}

variable "company" {
  description = "The company name for the organization"
  type        = string
  default     = null
}

variable "organization_name" {
  description = "The display name for the organization"
  type        = string
  default     = null
}

variable "organization_description" {
  description = "The description for the organization"
  type        = string
  default     = null
}

variable "default_repository_permission" {
  description = "The default permission for organization members"
  type        = string
  default     = "read"
}

variable "members_can_create_public_repositories" {
  description = "Whether organization members can create public repositories"
  type        = bool
  default     = false
}

variable "members_can_create_private_repositories" {
  description = "Whether organization members can create private repositories"
  type        = bool
  default     = true
}

variable "dependabot_alerts_enabled_for_new_repositories" {
  description = "Whether Dependabot alerts are enabled for new repositories"
  type        = bool
  default     = true
}

variable "secret_scanning_enabled_for_new_repositories" {
  description = "Whether secret scanning is enabled for new repositories"
  type        = bool
  default     = true
}

# Teams configuration
variable "github_teams" {
  description = "Map of GitHub teams to create"
  type = map(object({
    description = string
    privacy     = optional(string, "closed")
    members = map(string) # username => role (member or maintainer)
  }))
  default = {}
}

# Repositories configuration
variable "github_repositories" {
  description = "Map of GitHub repositories to create"
  type = map(object({
    description    = string
    visibility     = optional(string, "private")
    has_issues     = optional(bool, true)
    has_wiki       = optional(bool, false)
    has_projects   = optional(bool, true)
    has_discussions = optional(bool, false)
    topics         = optional(list(string), [])

    # Merge settings
    allow_merge_commit     = optional(bool, false)
    allow_squash_merge     = optional(bool, true)
    allow_rebase_merge     = optional(bool, false)
    delete_branch_on_merge = optional(bool, true)
    allow_auto_merge       = optional(bool, false)

    # Templates
    gitignore_template = optional(string, null)
    license_template   = optional(string, null)

    # Branch protection
    branch_protection = optional(map(object({
      required_status_checks = optional(object({
        strict   = optional(bool, false)
        contexts = optional(list(string), [])
      }))
      required_pull_request_reviews = optional(object({
        dismiss_stale_reviews           = optional(bool, false)
        require_code_owner_reviews      = optional(bool, false)
        required_approving_review_count = optional(number, 1)
      }))
      enforce_admins          = optional(bool, false)
      require_signed_commits  = optional(bool, false)
      required_linear_history = optional(bool, false)
    })), {})

    # Team permissions - map of team names to permission level
    team_permissions = optional(map(string), {})

    # Webhooks
    webhooks = optional(map(object({
      url           = string
      content_type  = optional(string, "json")
      events        = list(string)
      active        = optional(bool, true)
      rotation_days = optional(number, null) # Individual rotation period, defaults to global setting
    })), {})

    vulnerability_alerts = optional(bool, true)
  }))
  default = {}
}

