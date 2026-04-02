output "organization_id" {
  description = "The ID of the GitHub organization"
  value       = github_organization_settings.organization.id
}

output "organization_name" {
  description = "The name of the GitHub organization"
  value       = github_organization_settings.organization.name
}

