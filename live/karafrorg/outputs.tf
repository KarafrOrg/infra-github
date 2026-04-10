output "github_actions_organization_variables" {
  value = module.infra-github.github_actions_organization_variables
}

output "organization_id" {
  value = module.infra-github.organization_id
}

output "organization_name" {
  value = module.infra-github.organization_name
}

output "repository_id" {
  value = module.infra-github.repository_id
}

output "repository_node_id" {
  value = module.infra-github.repository_node_id
}

output "repository_name" {
  value = module.infra-github.repository_name
}

output "repository_full_name" {
  value = module.infra-github.repository_full_name
}

output "repository_html_url" {
  value = module.infra-github.repository_html_url
}

output "repository_ssh_clone_url" {
  value = module.infra-github.repository_ssh_clone_url
}

output "repository_http_clone_url" {
  value = module.infra-github.repository_http_clone_url
}

output "repository_git_clone_url" {
  value = module.infra-github.repository_git_clone_url
}

output "team_ids" {
  value = module.infra-github.team_ids
}

output "team_node_ids" {
  value = module.infra-github.team_node_ids
}

output "team_slugs" {
  value = module.infra-github.team_slugs
}

output "team_names" {
  value = module.infra-github.team_names
}

output "team_members_counts" {
  value = module.infra-github.team_members_counts
}

output "webhook_secrets" {
  value     = module.infra-github.webhook_secrets
  sensitive = true
}

output "webhook_secret_ids" {
  value = module.infra-github.webhook_secret_ids
}

output "webhook_secret_names" {
  value = module.infra-github.webhook_secret_names
}

output "webhook_secret_rotation_timestamps" {
  value = module.infra-github.webhook_secret_rotation_timestamps
}

output "webhook_metadata_secret_ids" {
  value = module.infra-github.webhook_metadata_secret_ids
}
