github_organization = "KarafrOrg"

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

github_organization_variables = {
  "GCP_WIF_RESOURCE_ID" = {
    value      = "projects/1019265211616/locations/global/workloadIdentityPools/github-actions-karafrorg/providers/oidc"
    visibility = "all"
  }
}

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
    topics       = ["infrastructure", "terraform", "ovh", "iac"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-cluster" = {
    description  = "Infrastructure repository for k8s cluster deployment"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["infrastructure", "ansible", "k8s", "gha", "iac"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-github" = {
    description  = "IAC repo GitHub orchestration"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["infrastructure", "terraform", "github", "iac"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-terraform" = {
    description  = "IAC repo Terraform cloud orchestration"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["infrastructure", "terraform", "terraform-cloud", "iac"]

    team_permissions = {
      platform-admins = "admin"
    }
  }
  "infra-cloudflare" = {
    description  = "IAC repo Cloudflare infrastructure"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["infrastructure", "terraform", "cloudflare", "iac"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-gcp" = {
    description  = "IAC repo GCP infrastructure"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["infrastructure", "terraform", "gcp", "iac"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-monitoring" = {
    description  = "Helm charts provisioning monitoring infrastructure within Kubernetes cluster"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["argocd", "helm", "k8s"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-network" = {
    description  = "Helm charts provisioning network infrastructure within Kubernetes cluster"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["argocd", "helm", "k8s"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-storage" = {
    description  = "Helm charts provisioning storage infrastructure within Kubernetes cluster"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["argocd", "helm", "k8s"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-secrets" = {
    description  = "Helm charts provisioning secrets management infrastructure within Kubernetes cluster"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["argocd", "helm", "k8s"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "infra-monitoring" = {
    description  = "Helm charts provisioning secrets management infrastructure within Kubernetes cluster"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["argocd", "helm", "k8s"]

    team_permissions = {
      platform-admins = "admin"
    }
  }

  "object-buckets" = {
    description  = "Provisions S3-compatible block storage buckets"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["helm", "k8s", "object-storage"]

    team_permissions = {
      platform-admins = "admin"
    }

    pages = {
      branch = "gh-pages"
      path   = "/"
    }
  }

  "edge-access" = {
    description  = "Allows access to services via internet"
    visibility   = "public"
    has_issues   = false
    has_projects = false
    topics       = ["helm", "k8s", "ingress"]

    team_permissions = {
      platform-admins = "admin"
    }

    pages = {
      branch = "gh-pages"
      path   = "/"
    }

    "actions-terraform-core" = {
      description  = " Core reusable actions and workflows for working with Terraform"
      visibility   = "public"
      has_issues   = false
      has_projects = false
      topics       = ["github-actions", "cicd", "reusable", "terraform"]

      team_permissions = {
        platform-admins = "admin"
      }
    }
  }
}
