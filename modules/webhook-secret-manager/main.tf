# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  project = var.gcp_project_name
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

# Rotation trigger - this will change every N days, forcing secret regeneration
# Each webhook has its own rotation period
resource "time_rotating" "webhook_secret_rotation" {
  for_each = var.webhook_configs

  rotation_days = coalesce(each.value.rotation_days, 90)
}

# Generate random webhook secrets
resource "random_password" "webhook_secret" {
  for_each = var.webhook_configs

  length  = var.secret_length
  special = true
  upper   = true
  lower   = true
  numeric = true

  # Force regeneration when rotation triggers
  keepers = {
    rotation_time = time_rotating.webhook_secret_rotation[each.key].id
  }
}

# Create Secret Manager secrets
resource "google_secret_manager_secret" "webhook_secret" {
  for_each = var.webhook_configs

  secret_id = "github-webhook-${each.value.repository_name}-${each.value.webhook_name}"
  project   = var.gcp_project_name

  labels = {
    type            = "github-webhook"
    repository      = each.value.repository_name
    webhook         = each.value.webhook_name
    managed_by      = "terraform"
    rotation_days   = tostring(coalesce(each.value.rotation_days, 90))
  }

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# Store the generated secret in Secret Manager
resource "google_secret_manager_secret_version" "webhook_secret" {
  for_each = var.webhook_configs

  secret      = google_secret_manager_secret.webhook_secret[each.key].id
  secret_data = random_password.webhook_secret[each.key].result
}

# Add rotation metadata as a separate secret for tracking
resource "google_secret_manager_secret" "webhook_secret_metadata" {
  for_each = var.webhook_configs

  secret_id = "github-webhook-${each.value.repository_name}-${each.value.webhook_name}-metadata"
  project   = var.gcp_project_name

  labels = {
    type       = "github-webhook-metadata"
    repository = each.value.repository_name
    webhook    = each.value.webhook_name
    managed_by = "terraform"
  }

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# Store rotation metadata
resource "google_secret_manager_secret_version" "webhook_secret_metadata" {
  for_each = var.webhook_configs

  secret = google_secret_manager_secret.webhook_secret_metadata[each.key].id
  secret_data = jsonencode({
    repository      = each.value.repository_name
    webhook_name    = each.value.webhook_name
    webhook_url     = each.value.url
    created_at      = timestamp()
    rotation_days   = coalesce(each.value.rotation_days, 90)
    next_rotation   = timeadd(timestamp(), "${coalesce(each.value.rotation_days, 90) * 24}h")
    secret_id       = google_secret_manager_secret.webhook_secret[each.key].secret_id
  })
}

