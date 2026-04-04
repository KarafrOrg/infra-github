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
    github_token        = store.varset.credentials.github_token
    github_organization = "KarafrOrg"

    gcp_project_name          = "karafra-net"
    gcp_region                = "us-central1"
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/1019265211616/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = store.varset.credentials.gcp_service_account_email

    webhook_secret_rotation_days = 90

    billing_email                 = "billing+github@karafra.net"
    company                       = "Example Company"
    organization_name             = "Example Organization"
    organization_description      = "Example GitHub Organization managed by Terraform"
    default_repository_permission = "read"

    members_can_create_public_repositories         = true
    members_can_create_private_repositories        = true
    dependabot_alerts_enabled_for_new_repositories = true
    secret_scanning_enabled_for_new_repositories   = true

    github_teams = {
      "argocd-admins" = {
        description = "ArgoCD Administrators"
        privacy     = "closed"
        members = {
          "karafra" = "maintainer"
        }
      }
      "platform-admins" = {
        description = "Platform Administrators"
        privacy     = "closed"
        members = {
          "karafra" = "maintainer"
        }
      }
    }

    github_repositories = {
      "infra-ovh" = {
        description = "Infrastructure repository for OVH deployment"
        visibility  = "public"
        has_issues  = false
        has_projects = false
        topics = ["infrastructure", "terraform", "ovh"]

        webhooks = {
          "ci-webhook" = {
            url           = "https://ci.example.com/webhook"
            content_type  = "json"
            events = ["push", "pull_request"]
            active        = true
            rotation_days = 30
          }
          "slack-webhook" = {
            url           = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
            content_type  = "json"
            events = ["push", "issues", "pull_request"]
            active        = true
            rotation_days = 180
          }
          "monitoring-webhook" = {
            url          = "https://monitoring.example.com/webhook"
            content_type = "json"
            events = ["push", "release"]
            active       = true
          }
        }

        team_permissions = {
          platform-admins = "admin"
        }
      }
    }
  }
}

