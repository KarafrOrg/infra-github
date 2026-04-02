store "varset" "credentials" {
  name     = "infra-github-variables"
  category = "terraform"
}

identity_token "gcp" {
  audience = [
    "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
  ]
}

deployment "production" {
  inputs = {
    # GitHub credentials
    github_token        = store.varset.credentials.github_token
    github_organization = "your-organization-name"

    # GCP Configuration for Secret Manager
    gcp_project_name          = "your-gcp-project-id"
    gcp_region                = "us-central1"
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = store.varset.credentials.gcp_service_account_email

    # Webhook secret rotation (90 days)
    webhook_secret_rotation_days = 90

    # Organization settings
    billing_email              = "billing@example.com"
    company                    = "Example Company"
    organization_name          = "Example Organization"
    organization_description   = "Example GitHub Organization managed by Terraform"
    default_repository_permission = "read"

    # Security settings
    members_can_create_public_repositories               = false
    members_can_create_private_repositories              = true
    dependabot_alerts_enabled_for_new_repositories       = true
    secret_scanning_enabled_for_new_repositories         = true

    # GitHub Teams
    github_teams = {
      "platform" = {
        description = "Platform Engineering Team"
        privacy     = "closed"
        members = {
          "user1" = "maintainer"
          "user2" = "member"
          "user3" = "member"
        }
      }
      "backend" = {
        description = "Backend Development Team"
        privacy     = "closed"
        members = {
          "user4" = "maintainer"
          "user5" = "member"
        }
      }
      "frontend" = {
        description = "Frontend Development Team"
        privacy     = "closed"
        members = {
          "user6" = "maintainer"
          "user7" = "member"
        }
      }
    }

    # GitHub Repositories
    github_repositories = {
      "infrastructure" = {
        description = "Infrastructure as Code repository"
        visibility  = "private"
        has_issues  = true
        has_wiki    = false
        has_projects = true
        topics      = ["terraform", "infrastructure", "iac"]

        allow_squash_merge     = true
        allow_merge_commit     = false
        delete_branch_on_merge = true

        branch_protection = {
          "main" = {
            required_status_checks = {
              strict   = true
              contexts = ["ci/terraform-validate", "ci/terraform-plan"]
            }
            required_pull_request_reviews = {
              dismiss_stale_reviews           = true
              require_code_owner_reviews      = true
              required_approving_review_count = 2
            }
            require_signed_commits  = true
            required_linear_history = true
          }
        }

        team_permissions = {
          "platform" = "admin"
          "backend"  = "push"
        }

        vulnerability_alerts = true
      }

      "backend-api" = {
        description = "Backend API service"
        visibility  = "private"
        has_issues  = true
        has_discussions = true
        has_projects = true
        has_wiki    = false
        topics      = ["api", "backend", "nodejs"]

        gitignore_template = "Node"
        license_template   = "mit"

        allow_squash_merge     = true
        allow_merge_commit     = false
        delete_branch_on_merge = true
        allow_auto_merge       = true

        branch_protection = {
          "main" = {
            required_status_checks = {
              strict   = true
              contexts = ["ci/test", "ci/lint", "ci/build"]
            }
            required_pull_request_reviews = {
              dismiss_stale_reviews           = true
              require_code_owner_reviews      = true
              required_approving_review_count = 1
            }
            required_linear_history = true
          }
          "develop" = {
            required_status_checks = {
              strict   = true
              contexts = ["ci/test", "ci/lint"]
            }
            required_pull_request_reviews = {
              required_approving_review_count = 1
            }
          }
        }

        team_permissions = {
          "backend"  = "admin"
          "platform" = "push"
        }

        vulnerability_alerts = true
      }

      "frontend-app" = {
        description = "Frontend application"
        visibility  = "private"
        has_issues  = true
        has_discussions = true
        has_projects = true
        has_wiki    = false
        topics      = ["frontend", "react", "typescript"]

        gitignore_template = "Node"
        license_template   = "mit"

        allow_squash_merge     = true
        allow_merge_commit     = false
        delete_branch_on_merge = true
        allow_auto_merge       = true

        branch_protection = {
          "main" = {
            required_status_checks = {
              strict   = true
              contexts = ["ci/test", "ci/lint", "ci/build"]
            }
            required_pull_request_reviews = {
              dismiss_stale_reviews           = true
              require_code_owner_reviews      = true
              required_approving_review_count = 1
            }
            required_linear_history = true
          }
        }

        team_permissions = {
          "frontend" = "admin"
          "platform" = "push"
        }

        vulnerability_alerts = true
      }

      "webhook-example" = {
        description = "Example repository with webhooks"
        visibility  = "private"
        has_issues  = true
        topics      = ["example", "webhooks"]

        webhooks = {
          "ci-webhook" = {
            url           = "https://ci.example.com/webhook"
            content_type  = "json"
            events        = ["push", "pull_request"]
            active        = true
            rotation_days = 30  # Rotate every 30 days (more frequent for CI)
          }
          "slack-webhook" = {
            url           = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
            content_type  = "json"
            events        = ["push", "issues", "pull_request"]
            active        = true
            rotation_days = 180  # Rotate every 180 days (less frequent for notifications)
          }
          "monitoring-webhook" = {
            url           = "https://monitoring.example.com/webhook"
            content_type  = "json"
            events        = ["push", "release"]
            active        = true
            # rotation_days not specified - uses global default (90 days)
          }
        }

        team_permissions = {
          "platform" = "admin"
        }
      }
    }
  }
}

