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
        path = try(pages.value.path, "/")
      }
      cname = try(pages.value.cname, null)
    }
  }
}

resource "github_repository_ruleset" "ruleset" {
  for_each = var.branch_protection

  name        = "protection-${each.key}"
  repository  = github_repository.repository.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = [each.key]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = try(each.value.enforce_admins, false) ? [] : [1]
    content {
      actor_id    = 5 # Repository admins
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }
  }

  rules {
    dynamic "pull_request" {
      for_each = try(each.value.required_pull_request_reviews, null) != null ? [1] : []
      content {
        required_approving_review_count   = try(each.value.required_pull_request_reviews.required_approving_review_count, 1)
        dismiss_stale_reviews_on_push     = try(each.value.required_pull_request_reviews.dismiss_stale_reviews, false)
        require_code_owner_review         = try(each.value.required_pull_request_reviews.require_code_owner_reviews, false)
        require_last_push_approval        = false
        required_review_thread_resolution = false
      }
    }

    dynamic "required_status_checks" {
      for_each = try(each.value.required_status_checks, null) != null ? [1] : []
      content {
        dynamic "required_check" {
          for_each = try(each.value.required_status_checks.contexts, [])
          content {
            context        = required_check.value
            integration_id = null
          }
        }
        strict_required_status_checks_policy = try(each.value.required_status_checks.strict, false)
      }
    }

    required_signatures = coalesce(try(each.value.require_signed_commits, null), false)
    required_linear_history = coalesce(try(each.value.required_linear_history, null), false)
    non_fast_forward = coalesce(try(each.value.allow_force_pushes, null), false)
    deletion = !try(each.value.allow_deletions, false)
  }
}

resource "github_team_repository" "team_repository" {
  for_each = var.team_permissions

  team_id    = var.team_ids[each.key]
  repository = github_repository.repository.name
  permission = each.value
}

resource "github_repository_collaborator" "collaborator" {
  for_each = var.collaborators

  repository = github_repository.repository.name
  username   = each.key
  permission = each.value
}

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

resource "github_repository_deploy_key" "deploy_key" {
  for_each = var.deploy_keys

  title      = each.key
  repository = github_repository.repository.name
  key        = each.value.key
  read_only  = try(each.value.read_only, true)
}
