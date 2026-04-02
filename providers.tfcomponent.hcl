required_providers {
  github = {
    source  = "integrations/github"
    version = "~> 6.11"
  }
  google = {
    source  = "hashicorp/google"
    version = "~> 7.24"
  }
  random = {
    source  = "hashicorp/random"
    version = "~> 3.6"
  }
  time = {
    source  = "hashicorp/time"
    version = "~> 0.12"
  }
}

provider "github" "main" {
  config {
    token = var.github_token
    owner = var.github_organization
  }
}

provider "google" "main" {
  config {
    project = var.gcp_project_name
    region  = var.gcp_region
    external_credentials {
      audience              = var.gcp_audience
      service_account_email = var.gcp_service_account_email
      identity_token        = var.gcp_identity_token
    }
  }
}

provider "random" "main" {
  config {}
}

provider "time" "main" {
  config {}
}

