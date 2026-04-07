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
    company                       = "KarafrOrg"
    organization_name             = "KarafrOrg"
    organization_description      = "Homelab crap"
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
        description  = "Infrastructure repository for OVH deployment"
        visibility   = "public"
        has_issues   = false
        has_projects = false
        topics = ["infrastructure", "terraform", "ovh"]

        team_permissions = {
          platform-admins = "admin"
        }
      }

      "infra-cluster" = {
        description  = "Infrastructure repository for k8s cluster deployment"
        visibility   = "public"
        has_issues   = false
        has_projects = false
        topics = ["infrastructure", "ansible", "k8s", "gha"]

        team_permissions = {
          platform-admins = "admin"
        }
      }
    }

    organization_variables = {
      "gcp_wif_resource_id" = {
        value      = "projects/1019265211616/locations/global/workloadIdentityPools/github-actions/providers/github-oidc"
        visibility = "all"
      }
    }
  }
}

