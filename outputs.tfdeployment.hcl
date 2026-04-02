output "organization_id" {
  type        = string
  description = "The ID of the GitHub organization"
  value       = component.github-organization.organization_id
}

output "teams" {
  type        = map(string)
  description = "Map of team names to their IDs"
  value       = { for k, v in component.github-teams : k => v.team_id }
}

output "repositories" {
  type = map(object({
    id       = number
    name     = string
    html_url = string
  }))
  description = "Map of repository names to their details"
  value = {
    for k, v in component.github-repositories : k => {
      id       = v.repository_id
      name     = v.repository_name
      html_url = v.repository_html_url
    }
  }
}

output "webhook_secret_ids" {
  type        = map(string)
  description = "Map of webhook secret IDs in GCP Secret Manager"
  value       = component.webhook-secret-manager.secret_ids
}

output "webhook_rotation_timestamps" {
  type        = map(string)
  description = "Map of webhook secret rotation timestamps"
  value       = component.webhook-secret-manager.rotation_timestamps
}

output "webhook_metadata_secret_ids" {
  type        = map(string)
  description = "Map of webhook metadata secret IDs in GCP Secret Manager"
  value       = component.webhook-secret-manager.metadata_secret_ids
}

