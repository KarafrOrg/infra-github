variable "name" {
  description = "The name of the repository"
  type        = string
}

variable "description" {
  description = "A description of the repository"
  type        = string
  default     = ""
}

variable "visibility" {
  description = "The visibility of the repository (public, private, or internal)"
  type        = string
  default     = "private"
  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of: public, private, internal"
  }
}

variable "homepage_url" {
  description = "URL of a page describing the project"
  type        = string
  default     = null
}

variable "has_issues" {
  description = "Enable the GitHub Issues features on the repository"
  type        = bool
  default     = true
}

variable "has_discussions" {
  description = "Enable GitHub Discussions on the repository"
  type        = bool
  default     = false
}

variable "has_projects" {
  description = "Enable the GitHub Projects features on the repository"
  type        = bool
  default     = true
}

variable "has_wiki" {
  description = "Enable the GitHub Wiki features on the repository"
  type        = bool
  default     = true
}


variable "is_template" {
  description = "Set to true to make this repository available as a template"
  type        = bool
  default     = false
}

variable "allow_merge_commit" {
  description = "Set to true to allow merge commits"
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Set to true to allow squash merges"
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Set to true to allow rebase merges"
  type        = bool
  default     = true
}

variable "allow_auto_merge" {
  description = "Set to true to allow auto-merge on pull requests"
  type        = bool
  default     = false
}

variable "squash_merge_commit_title" {
  description = "The default value for a squash merge commit title"
  type        = string
  default     = "COMMIT_OR_PR_TITLE"
  validation {
    condition     = contains(["PR_TITLE", "COMMIT_OR_PR_TITLE"], var.squash_merge_commit_title)
    error_message = "Must be one of: PR_TITLE, COMMIT_OR_PR_TITLE"
  }
}

variable "squash_merge_commit_message" {
  description = "The default value for a squash merge commit message"
  type        = string
  default     = "COMMIT_MESSAGES"
  validation {
    condition     = contains(["PR_BODY", "COMMIT_MESSAGES", "BLANK"], var.squash_merge_commit_message)
    error_message = "Must be one of: PR_BODY, COMMIT_MESSAGES, BLANK"
  }
}

variable "merge_commit_title" {
  description = "The default value for a merge commit title"
  type        = string
  default     = "MERGE_MESSAGE"
  validation {
    condition     = contains(["PR_TITLE", "MERGE_MESSAGE"], var.merge_commit_title)
    error_message = "Must be one of: PR_TITLE, MERGE_MESSAGE"
  }
}

variable "merge_commit_message" {
  description = "The default value for a merge commit message"
  type        = string
  default     = "PR_TITLE"
  validation {
    condition     = contains(["PR_BODY", "PR_TITLE", "BLANK"], var.merge_commit_message)
    error_message = "Must be one of: PR_BODY, PR_TITLE, BLANK"
  }
}

variable "delete_branch_on_merge" {
  description = "Automatically delete head branch after a pull request is merged"
  type        = bool
  default     = true
}

variable "gitignore_template" {
  description = "Use the name of the template without the extension"
  type        = string
  default     = null
}

variable "license_template" {
  description = "Use the name of the template without the extension"
  type        = string
  default     = null
}

variable "archived" {
  description = "Specifies if the repository should be archived"
  type        = bool
  default     = false
}

variable "archive_on_destroy" {
  description = "Set to true to archive the repository instead of deleting on destroy"
  type        = bool
  default     = true
}

variable "topics" {
  description = "The list of topics of the repository"
  type        = list(string)
  default     = []
}

variable "vulnerability_alerts" {
  description = "Set to true to enable security alerts for vulnerable dependencies"
  type        = bool
  default     = true
}

variable "template" {
  description = "Template repository to use"
  type = object({
    owner      = string
    repository = string
  })
  default = null
}

variable "pages" {
  description = "GitHub Pages configuration"
  type = object({
    branch = string
    path   = optional(string)
    cname  = optional(string)
  })
  default = null
}

variable "branch_protection" {
  description = "Branch protection rules"
  type = map(object({
    required_status_checks = optional(object({
      strict   = optional(bool)
      contexts = optional(list(string))
    }))
    required_pull_request_reviews = optional(object({
      dismiss_stale_reviews           = optional(bool)
      restrict_dismissals             = optional(bool)
      dismissal_restrictions          = optional(list(string))
      pull_request_bypassers          = optional(list(string))
      require_code_owner_reviews      = optional(bool)
      required_approving_review_count = optional(number)
    }))
    enforce_admins         = optional(bool)
    require_signed_commits = optional(bool)
    required_linear_history = optional(bool)
    allow_force_pushes     = optional(bool)
    allow_deletions        = optional(bool)
  }))
  default = {}
}

variable "team_permissions" {
  description = "Map of team names to their permissions (pull, triage, push, maintain, admin)"
  type        = map(string)
  default     = {}
}

variable "team_ids" {
  description = "Map of team names to their IDs (provided by component dependency)"
  type        = map(string)
  default     = {}
}

variable "collaborators" {
  description = "Map of GitHub usernames to their permissions (pull, triage, push, maintain, admin)"
  type        = map(string)
  default     = {}
}

variable "webhooks" {
  description = "Repository webhooks"
  type = map(object({
    url          = string
    content_type = optional(string)
    insecure_ssl = optional(bool)
    secret       = optional(string)
    active       = optional(bool)
    events       = list(string)
  }))
  default = {}
}

variable "webhook_secrets" {
  description = "Map of webhook secrets (from webhook-secret-manager module)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "deploy_keys" {
  description = "Deploy keys for the repository"
  type = map(object({
    key       = string
    read_only = optional(bool)
  }))
  default = {}
}

