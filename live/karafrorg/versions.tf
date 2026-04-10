terraform {
  required_providers {
    github = {
      source = "integrations/github"
    }
    google = {
      source = "hashicorp/google"
    }
    random = {
      source = "hashicorp/random"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_organization
}

