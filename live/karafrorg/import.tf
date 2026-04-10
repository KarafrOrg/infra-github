
import {
  id = "infra-ovh"
  to = module.infra-github.module.github_repository["infra-ovh"].github_repository.repository
}

import {
  id = "infra-cluster"
  to = module.infra-github.module.github_repository["infra-cluster"].github_repository.repository
}

import {
  id = "infra-github"
  to = module.infra-github.module.github_repository["infra-github"].github_repository.repository
}

import {
  id = "infra-terraform"
  to = module.infra-github.module.github_repository["infra-terraform"].github_repository.repository
}

import {
  id = "infra-cloudflare"
  to = module.infra-github.module.github_repository["infra-cloudflare"].github_repository.repository
}

import {
  id = "infra-network"
  to = module.infra-github.module.github_repository["infra-network"].github_repository.repository
}

import {
  id = "infra-storage"
  to = module.infra-github.module.github_repository["infra-storage"].github_repository.repository
}

import {
  id = "infra-secrets"
  to = module.infra-github.module.github_repository["infra-secrets"].github_repository.repository
}

import {
  id = "infra-gcp"
  to = module.infra-github.module.github_repository["infra-gcp"].github_repository.repository
}

import {
  id = "infra-monitoring"
  to = module.infra-github.module.github_repository["infra-monitoring"].github_repository.repository
}

import {
  id = "object-buckets"
  to = module.infra-github.module.github_repository["object-buckets"].github_repository.repository
}

import {
  id = "edge-access"
  to = module.infra-github.module.github_repository["edge-access"].github_repository.repository
}
