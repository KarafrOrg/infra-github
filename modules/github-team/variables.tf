variable "name" {
  description = "The name of the team"
  type        = string
}

variable "description" {
  description = "A description of the team"
  type        = string
  default     = ""
}

variable "privacy" {
  description = "The level of privacy for the team (secret or closed)"
  type        = string
  default     = "closed"
  validation {
    condition     = contains(["secret", "closed"], var.privacy)
    error_message = "Privacy must be either 'secret' or 'closed'"
  }
}

variable "parent_team_id" {
  description = "The ID of the parent team"
  type        = string
  default     = null
}

variable "ldap_dn" {
  description = "The LDAP Distinguished Name of the group"
  type        = string
  default     = null
}

variable "members" {
  description = "Map of GitHub usernames to their role (member or maintainer)"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for role in values(var.members) : contains(["member", "maintainer"], role)
    ])
    error_message = "All member roles must be either 'member' or 'maintainer'"
  }
}
