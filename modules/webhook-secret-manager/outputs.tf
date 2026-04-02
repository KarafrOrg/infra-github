output "webhook_secrets" {
  description = "Map of webhook secrets (sensitive)"
  value = {
    for k, v in random_password.webhook_secret : k => v.result
  }
  sensitive = true
}

output "secret_ids" {
  description = "Map of GCP Secret Manager secret IDs"
  value = {
    for k, v in google_secret_manager_secret.webhook_secret : k => v.secret_id
  }
}

output "secret_names" {
  description = "Map of GCP Secret Manager secret full names"
  value = {
    for k, v in google_secret_manager_secret.webhook_secret : k => v.name
  }
}

output "rotation_timestamps" {
  description = "Map of rotation timestamps for tracking"
  value = {
    for k, v in time_rotating.webhook_secret_rotation : k => v.rotation_rfc3339
  }
}

output "metadata_secret_ids" {
  description = "Map of metadata secret IDs"
  value = {
    for k, v in google_secret_manager_secret.webhook_secret_metadata : k => v.secret_id
  }
}

