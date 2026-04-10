resource "time_rotating" "webhook_secret_rotation" {
  for_each = var.webhook_configs

  rotation_days = coalesce(each.value.rotation_days, local.default_rotation_days)
}

resource "random_password" "webhook_secret" {
  for_each = var.webhook_configs

  length  = var.secret_length
  special = true
  upper   = true
  lower   = true
  numeric = true

  keepers = {
    rotation_time = time_rotating.webhook_secret_rotation[each.key].id
  }
}

resource "google_secret_manager_secret" "webhook_secret" {
  for_each = var.webhook_configs

  secret_id = "github-webhook-${each.value.repository_name}-${each.value.webhook_name}"

  labels = {
    type          = "github-webhook"
    repository    = each.value.repository_name
    webhook       = each.value.webhook_name
    managed-by    = "terraform"
    rotation_days = tostring(coalesce(each.value.rotation_days, local.default_rotation_days))
  }

  annotations = {
    type          = "github-webhook"
    repository    = each.value.repository_name
    webhook       = each.value.webhook_name
    managed-by    = "terraform"
    rotation_days = tostring(coalesce(each.value.rotation_days, local.default_rotation_days))
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "webhook_secret" {
  for_each = var.webhook_configs

  secret      = google_secret_manager_secret.webhook_secret[each.key].id
  secret_data = random_password.webhook_secret[each.key].result

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_secret_manager_secret" "webhook_secret_metadata" {
  for_each = var.webhook_configs

  secret_id = "github-webhook-${each.value.repository_name}-${each.value.webhook_name}-metadata"

  labels = {
    type       = "github-webhook-metadata"
    repository = each.value.repository_name
    webhook    = each.value.webhook_name
    managed-by = "terraform"
  }

  annotations = {
    type       = "github-webhook-metadata"
    repository = each.value.repository_name
    webhook    = each.value.webhook_name
    managed-by = "terraform"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "webhook_secret_metadata" {
  for_each = var.webhook_configs

  secret = google_secret_manager_secret.webhook_secret_metadata[each.key].id
  secret_data = jsonencode({
    repository    = each.value.repository_name
    webhook_name  = each.value.webhook_name
    webhook_url   = each.value.url
    created_at    = time_rotating.webhook_secret_rotation[each.key].rotation_rfc3339
    rotation_days = coalesce(each.value.rotation_days, local.default_rotation_days)
    next_rotation = time_rotating.webhook_secret_rotation[each.key].rotation_rfc3339
    secret_id     = google_secret_manager_secret.webhook_secret[each.key].secret_id
  })

  lifecycle {
    create_before_destroy = true
  }
}
