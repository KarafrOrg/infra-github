output "github_actions_organization_variables" {
  value = module.github-actions-organization.github_actions_organization_variables
}

output "organization_id" {
  value = module.github_organization.organization_id
}

output "organization_name" {
  value = module.github_organization.organization_name
}

output "repository_id" {
  value = { for k, v in module.github_repository : k => v.repository_id }
}

output "repository_node_id" {
  value = { for k, v in module.github_repository : k => v.repository_node_id }
}

output "repository_name" {
  value = { for k, v in module.github_repository : k => v.repository_name }
}

output "repository_full_name" {
  value = { for k, v in module.github_repository : k => v.repository_full_name }
}

output "repository_html_url" {
  value = { for k, v in module.github_repository : k => v.repository_html_url }
}

output "repository_ssh_clone_url" {
  value = { for k, v in module.github_repository : k => v.repository_ssh_clone_url }
}

output "repository_http_clone_url" {
  value = { for k, v in module.github_repository : k => v.repository_http_clone_url }
}

output "repository_git_clone_url" {
  value = { for k, v in module.github_repository : k => v.repository_git_clone_url }
}

output "team_ids" {
  value = { for k, v in module.github_teams : k => v.team_id }
}

output "team_node_ids" {
  value = { for k, v in module.github_teams : k => v.team_node_id }
}

output "team_slugs" {
  value = { for k, v in module.github_teams : k => v.team_slug }
}

output "team_names" {
  value = { for k, v in module.github_teams : k => v.team_name }
}

output "team_members_counts" {
  value = { for k, v in module.github_teams : k => v.team_members_count }
}

output "webhook_secrets" {
  value = module.webhook_secret_manager.webhook_secrets
}

output "webhook_secret_ids" {
  value = module.webhook_secret_manager.secret_ids
}

output "webhook_secret_names" {
  value = module.webhook_secret_manager.secret_names
}

output "webhook_secret_rotation_timestamps" {
  value = module.webhook_secret_manager.rotation_timestamps
}

output "webhook_metadata_secret_ids" {
  value = module.webhook_secret_manager.metadata_secret_ids
}
