component "github-organization" {
  source = "./modules/github-organization"

  providers = {
    github = provider.github.main
  }

  inputs = {
    billing_email                                  = var.billing_email
    company                                        = var.company
    name                                           = var.organization_name
    description                                    = var.organization_description
    default_repository_permission                  = var.default_repository_permission
    members_can_create_public_repositories         = var.members_can_create_public_repositories
    members_can_create_private_repositories        = var.members_can_create_private_repositories
    dependabot_alerts_enabled_for_new_repositories = var.dependabot_alerts_enabled_for_new_repositories
    secret_scanning_enabled_for_new_repositories   = var.secret_scanning_enabled_for_new_repositories
  }
}

component "github-teams" {
  source   = "./modules/github-team"
  for_each = var.github_teams

  providers = {
    github = provider.github.main
  }

  inputs = {
    name        = each.key
    description = each.value.description
    privacy     = each.value.privacy
    members     = each.value.members
  }
}

component "webhook-secret-manager" {
  source = "./modules/webhook-secret-manager"

  providers = {
    google = provider.google.main
    random = provider.random.main
    time   = provider.time.main
  }

  inputs = {
    gcp_project_name = var.gcp_project_name

    webhook_configs = merge([
      for repo_name, repo_config in var.github_repositories : {
        for webhook_name, webhook_config in try(repo_config.webhooks, {}) :
        "${repo_name}-${webhook_name}" => {
          repository_name = repo_name
          webhook_name    = webhook_name
          url             = webhook_config.url
          rotation_days = try(webhook_config.rotation_days, var.webhook_secret_rotation_days)
        }
      }
    ]...)
  }
}

component "github-repositories" {
  source   = "./modules/github-repository"
  for_each = var.github_repositories

  providers = {
    github = provider.github.main
  }

  inputs = {
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

    team_ids = {for k, v in component.github-teams : k => v.team_id}

    webhook_secrets = component.webhook-secret-manager.webhook_secrets
  }

  depends_on = [
    component.github-teams,
    component.webhook-secret-manager
  ]
}

removed {
  source = "./modules/github-repository"
  from   = component.github-repositories["infrastructure"]

  providers = {
    github = provider.github.main
  }

  lifecycle {
    destroy = true
  }
}

removed {
  source = "./modules/github-repository"
  from   = component.github-repositories["backend-api"]

  providers = {
    github = provider.github.main
  }

  lifecycle {
    destroy = true
  }
}

removed {
  source = "./modules/github-repository"
  from   = component.github-repositories["frontend-app"]

  providers = {
    github = provider.github.main
  }

  lifecycle {
    destroy = true
  }
}

removed {
  source = "./modules/github-team"
  from   = component.github-teams["frontend"]

  providers = {
    github = provider.github.main
  }

  lifecycle {
    destroy = true
  }
}

removed {
  source = "./modules/github-team"
  from   = component.github-teams["backend"]

  providers = {
    github = provider.github.main
  }

  lifecycle {
    destroy = true
  }
}


removed {
  source = "./modules/github-team"
  from   = component.github-teams["platform"]

  providers = {
    github = provider.github.main
  }

  lifecycle {
    destroy = true
  }
}
