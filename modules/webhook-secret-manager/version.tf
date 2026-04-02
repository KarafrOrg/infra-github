terraform {
  required_providers {
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
}

