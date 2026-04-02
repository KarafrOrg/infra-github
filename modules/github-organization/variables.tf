variable "billing_email" {
  description = "The billing email address for the organization"
  type        = string
}

variable "company" {
  description = "The company name for the organization"
  type        = string
  default     = null
}

variable "blog" {
  description = "The blog URL for the organization"
  type        = string
  default     = null
}

variable "email" {
  description = "The email address for the organization"
  type        = string
  default     = null
}

variable "twitter_username" {
  description = "The Twitter username for the organization"
  type        = string
  default     = null
}

variable "location" {
  description = "The location for the organization"
  type        = string
  default     = null
}

variable "name" {
  description = "The name for the organization"
  type        = string
  default     = null
}

variable "description" {
  description = "The description for the organization"
  type        = string
  default     = null
}

variable "has_organization_projects" {
  description = "Whether organization projects are enabled"
  type        = bool
  default     = true
}

variable "has_repository_projects" {
  description = "Whether repository projects are enabled"
  type        = bool
  default     = true
}

variable "default_repository_permission" {
  description = "The default permission for organization members"
  type        = string
  default     = "read"
  validation {
    condition     = contains(["read", "write", "admin", "none"], var.default_repository_permission)
    error_message = "Default repository permission must be one of: read, write, admin, none"
  }
}

variable "members_can_create_repositories" {
  description = "Whether organization members can create repositories"
  type        = bool
  default     = true
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

variable "members_can_create_internal_repositories" {
  description = "Whether organization members can create internal repositories"
  type        = bool
  default     = false
}

variable "members_can_create_pages" {
  description = "Whether organization members can create pages"
  type        = bool
  default     = true
}

variable "members_can_create_public_pages" {
  description = "Whether organization members can create public pages"
  type        = bool
  default     = true
}

variable "members_can_create_private_pages" {
  description = "Whether organization members can create private pages"
  type        = bool
  default     = true
}

variable "members_can_fork_private_repositories" {
  description = "Whether organization members can fork private repositories"
  type        = bool
  default     = false
}

variable "web_commit_signoff_required" {
  description = "Whether web commit signoff is required"
  type        = bool
  default     = false
}

variable "advanced_security_enabled_for_new_repositories" {
  description = "Whether advanced security is enabled for new repositories"
  type        = bool
  default     = false
}

variable "dependabot_alerts_enabled_for_new_repositories" {
  description = "Whether Dependabot alerts are enabled for new repositories"
  type        = bool
  default     = true
}

variable "dependabot_security_updates_enabled_for_new_repositories" {
  description = "Whether Dependabot security updates are enabled for new repositories"
  type        = bool
  default     = true
}

variable "dependency_graph_enabled_for_new_repositories" {
  description = "Whether dependency graph is enabled for new repositories"
  type        = bool
  default     = true
}

variable "secret_scanning_enabled_for_new_repositories" {
  description = "Whether secret scanning is enabled for new repositories"
  type        = bool
  default     = false
}

variable "secret_scanning_push_protection_enabled_for_new_repositories" {
  description = "Whether secret scanning push protection is enabled for new repositories"
  type        = bool
  default     = false
}

