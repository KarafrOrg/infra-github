resource "github_repository" "repository" {
  name        = var.name
  description = var.description
  visibility  = var.visibility

  homepage_url = var.homepage_url

  has_issues      = var.has_issues
  has_discussions = var.has_discussions
  has_projects    = var.has_projects
  has_wiki        = var.has_wiki

  is_template = var.is_template

  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message
  merge_commit_title          = var.merge_commit_title
  merge_commit_message        = var.merge_commit_message
  delete_branch_on_merge      = var.delete_branch_on_merge

  auto_init          = var.auto_init
  gitignore_template = var.gitignore_template
  license_template   = var.license_template

  archived           = var.archived
  archive_on_destroy = var.archive_on_destroy

  topics = var.topics

  vulnerability_alerts = var.vulnerability_alerts

  dynamic "template" {
    for_each = var.template != null ? [var.template] : []
    content {
      owner      = template.value.owner
      repository = template.value.repository
    }
  }

  dynamic "pages" {
    for_each = var.pages != null ? [var.pages] : []
    content {
      source {
        branch = pages.value.branch
        path   = try(pages.value.path, "/")
      }
      cname = try(pages.value.cname, null)
    }
  }
}

# Branch protection rules
resource "github_branch_protection" "protection" {
  for_each = var.branch_protection

  repository_id = github_repository.repository.node_id
  pattern       = each.key

  required_status_checks {
    strict   = try(each.value.required_status_checks.strict, false)
    contexts = try(each.value.required_status_checks.contexts, [])
  }

  required_pull_request_reviews {
    dismiss_stale_reviews           = try(each.value.required_pull_request_reviews.dismiss_stale_reviews, false)
    restrict_dismissals             = try(each.value.required_pull_request_reviews.restrict_dismissals, false)
    dismissal_restrictions          = try(each.value.required_pull_request_reviews.dismissal_restrictions, [])
    pull_request_bypassers          = try(each.value.required_pull_request_reviews.pull_request_bypassers, [])
    require_code_owner_reviews      = try(each.value.required_pull_request_reviews.require_code_owner_reviews, false)
    required_approving_review_count = try(each.value.required_pull_request_reviews.required_approving_review_count, 1)
  }

  enforce_admins         = try(each.value.enforce_admins, false)
  require_signed_commits = try(each.value.require_signed_commits, false)

  required_linear_history = try(each.value.required_linear_history, false)
  allows_force_pushes     = try(each.value.allow_force_pushes, false)
  allows_deletions        = try(each.value.allow_deletions, false)
}

# Team access to repository
resource "github_team_repository" "team_repository" {
  for_each = var.team_permissions

  team_id    = var.team_ids[each.key]
  repository = github_repository.repository.name
  permission = each.value
}

# Collaborator access to repository
resource "github_repository_collaborator" "collaborator" {
  for_each = var.collaborators

  repository = github_repository.repository.name
  username   = each.key
  permission = each.value
}

# Repository webhooks
resource "github_repository_webhook" "webhook" {
  for_each = var.webhooks

  repository = github_repository.repository.name

  configuration {
    url          = each.value.url
    content_type = try(each.value.content_type, "json")
    insecure_ssl = try(each.value.insecure_ssl, false)
    secret       = try(var.webhook_secrets["${var.name}-${each.key}"], try(each.value.secret, null))
  }

  active = try(each.value.active, true)
  events = each.value.events
}

# Deploy keys
resource "github_repository_deploy_key" "deploy_key" {
  for_each = var.deploy_keys

  title      = each.key
  repository = github_repository.repository.name
  key        = each.value.key
  read_only  = try(each.value.read_only, true)
}

