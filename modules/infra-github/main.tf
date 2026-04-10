module "github_organization" {
  source = "../github-organization"

  billing_email                                                = var.billing_email
  company                                                      = var.company
  name                                                         = var.organization_name
  description                                                  = var.organization_description
  default_repository_permission                                = var.default_repository_permission
  members_can_create_public_repositories                       = var.members_can_create_public_repositories
  members_can_create_private_repositories                      = var.members_can_create_private_repositories
  dependabot_alerts_enabled_for_new_repositories               = var.dependabot_alerts_enabled_for_new_repositories
  secret_scanning_enabled_for_new_repositories                 = var.secret_scanning_enabled_for_new_repositories
  advanced_security_enabled_for_new_repositories               = var.advanced_security_enabled_for_new_repositories
  blog                                                         = var.blog
  dependabot_security_updates_enabled_for_new_repositories     = var.dependabot_security_updates_enabled_for_new_repositories
  dependency_graph_enabled_for_new_repositories                = var.dependency_graph_enabled_for_new_repositories
  email                                                        = var.email
  location                                                     = var.location
  members_can_create_internal_repositories                     = var.members_can_create_internal_repositories
  members_can_create_pages                                     = var.members_can_create_pages
  members_can_create_private_pages                             = var.members_can_create_private_pages
  members_can_create_public_pages                              = var.members_can_create_public_pages
  members_can_create_repositories                              = var.members_can_create_repositories
  members_can_fork_private_repositories                        = var.members_can_fork_private_repositories
  secret_scanning_push_protection_enabled_for_new_repositories = var.secret_scanning_push_protection_enabled_for_new_repositories
  twitter_username                                             = var.twitter_username
  web_commit_signoff_required                                  = var.web_commit_signoff_required
}

module "github-actions-organization" {
  source = "../github-actions-organization"

  variables = var.github_organization_variables
}

module "github_teams" {
  source   = "../github-team"
  for_each = var.github_teams

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy
  members     = each.value.members

}

module "webhook_secret_manager" {
  source = "../webhook-secret-manager"

  webhook_configs = merge([
    for repo_name, repo_config in var.github_repositories : {
      for webhook_name, webhook_config in try(repo_config.webhooks, {}) :
      "${repo_name}-${webhook_name}" => {
        repository_name = repo_name
        webhook_name    = webhook_name
        url             = webhook_config.url
        rotation_days   = try(webhook_config.rotation_days, var.webhook_secret_rotation_days)
      }
    }
  ]...)
}

module "github_repository" {
  source   = "../github-repository"
  for_each = var.github_repositories

  name                   = each.key
  description            = each.value.description
  visibility             = each.value.visibility
  has_issues             = each.value.has_issues
  has_wiki               = each.value.has_wiki
  has_projects           = each.value.has_projects
  has_discussions        = each.value.has_discussions
  topics                 = each.value.topics
  allow_merge_commit     = each.value.allow_merge_commit
  allow_squash_merge     = each.value.allow_squash_merge
  allow_rebase_merge     = each.value.allow_rebase_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge
  allow_auto_merge       = each.value.allow_auto_merge
  gitignore_template     = each.value.gitignore_template
  license_template       = each.value.license_template
  branch_protection      = each.value.branch_protection
  team_permissions       = each.value.team_permissions
  webhooks               = each.value.webhooks
  vulnerability_alerts   = each.value.vulnerability_alerts
  pages                  = each.value.pages

  team_ids = { for k, v in module.github_teams : k => v.team_id }

  webhook_secrets = module.webhook_secret_manager.webhook_secrets

}
