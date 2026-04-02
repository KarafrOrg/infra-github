variable "gcp_project_name" {
  description = "GCP project name"
  type        = string
}

variable "webhook_configs" {
  description = "Map of webhook configurations requiring secrets"
  type = map(object({
    repository_name = string
    webhook_name    = string
    url             = string
    rotation_days   = number
  }))
}

variable "secret_length" {
  description = "Length of generated webhook secrets"
  type        = number
  default     = 32
}

