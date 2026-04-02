# Webhook Secret Management

This document explains how webhook secrets are automatically generated, stored in GCP Secret Manager, and rotated.

## Overview

The infrastructure automatically:
1. **Generates** cryptographically secure random secrets for each webhook
2. **Stores** them in GCP Secret Manager with proper labeling
3. **Rotates** them automatically every N days (default: 90 days)
4. **Applies** them to GitHub webhooks seamlessly

## Architecture

```
┌─────────────────────┐
│  Terraform Stack    │
│  (Components)       │
└──────────┬──────────┘
           │
           ├─────────────────────────────────┐
           │                                 │
           ▼                                 ▼
┌──────────────────────┐        ┌──────────────────────┐
│ webhook-secret-      │        │ github-repository    │
│ manager component    │        │ component            │
│                      │        │                      │
│ - Generates secrets  │───────▶│ - Uses secrets for   │
│ - Stores in GCP SM   │        │   webhook config     │
│ - Manages rotation   │        │                      │
└──────────────────────┘        └──────────────────────┘
           │
           ▼
┌──────────────────────┐
│  GCP Secret Manager  │
│                      │
│  Secrets:            │
│  - webhook secrets   │
│  - metadata          │
└──────────────────────┘
```

## Secret Structure

### Webhook Secret
- **Name Pattern**: `github-webhook-{repository}-{webhook-name}`
- **Value**: 32-character random string with letters, numbers, and special characters
- **Labels**:
  - `type`: `github-webhook`
  - `repository`: Repository name
  - `webhook`: Webhook name
  - `managed_by`: `terraform`
  - `rotation_days`: Number of days between rotations

### Metadata Secret
- **Name Pattern**: `github-webhook-{repository}-{webhook-name}-metadata`
- **Value**: JSON containing:
  ```json
  {
    "repository": "repo-name",
    "webhook_name": "webhook-name",
    "webhook_url": "https://...",
    "created_at": "2026-04-02T10:30:00Z",
    "rotation_days": 90,
    "next_rotation": "2026-07-01T10:30:00Z",
    "secret_id": "github-webhook-repo-name-webhook-name"
  }
  ```

## Configuration

### Basic Setup

In `deployments.tfdeploy.hcl`:

```hcl
deployment "production" {
  inputs = {
    # GCP Configuration (required for Secret Manager)
    gcp_project_name          = "your-gcp-project-id"
    gcp_region                = "us-central1"
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/123456/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = store.varset.credentials.gcp_service_account_email
    
    # Webhook secret rotation period
    webhook_secret_rotation_days = 90  # Rotate every 90 days
    
    # Repositories with webhooks
    github_repositories = {
      "my-repo" = {
        description = "Repository with webhook"
        
        webhooks = {
          "ci-webhook" = {
            url    = "https://ci.example.com/webhook"
            events = ["push", "pull_request"]
            # No need to specify 'secret' - it's auto-generated!
          }
        }
      }
    }
  }
}
```

### Custom Rotation Period

Configure rotation frequency globally or per webhook:

```hcl
# Global default rotation period (fallback)
webhook_secret_rotation_days = 90

# Per-webhook rotation (overrides global default)
github_repositories = {
  "my-repo" = {
    webhooks = {
      "ci-webhook" = {
        url           = "https://ci.example.com/webhook"
        events        = ["push", "pull_request"]
        rotation_days = 30  # Rotate every 30 days (more frequent)
      }
      "slack-webhook" = {
        url           = "https://hooks.slack.com/webhook"
        events        = ["push", "issues"]
        rotation_days = 180  # Rotate every 180 days (less frequent)
      }
      "monitoring" = {
        url    = "https://monitor.example.com/webhook"
        events = ["release"]
        # No rotation_days specified - uses global default (90 days)
      }
    }
  }
}
```

## Rotation Behavior

### How Rotation Works

1. **Time Trigger**: The `time_rotating` resource tracks rotation periods
2. **Secret Regeneration**: When rotation period expires:
   - New random secret is generated
   - New version is added to GCP Secret Manager
   - GitHub webhook is updated with new secret
3. **Automatic Update**: GitHub webhook automatically uses the latest secret version

### Rotation Timeline

```
Day 0:    Secret created
Day 1-89: Secret in use (no changes)
Day 90:   Rotation triggered
          └─> New secret generated
          └─> Stored in Secret Manager
          └─> Applied to GitHub webhook
Day 91+:  New secret in use
```

### Manual Rotation

To force immediate rotation:

```bash
# Taint the rotation resource
terraform taint 'component.webhook-secret-manager.time_rotating.webhook_secret_rotation["repo-webhook"]'

# Apply to regenerate
terraform apply
```

## Accessing Secrets

### From Terraform Outputs

```bash
# List all webhook secret IDs
terraform output webhook_secret_ids

# Check rotation timestamps
terraform output webhook_rotation_timestamps
```

### From GCP Console

1. Go to **Secret Manager** in GCP Console
2. Filter by label: `type=github-webhook`
3. Click on a secret to view versions and metadata

### Using gcloud CLI

```bash
# List all webhook secrets
gcloud secrets list --filter="labels.type=github-webhook" --project=your-project-id

# Get secret value (requires appropriate IAM permissions)
gcloud secrets versions access latest --secret="github-webhook-repo-name-webhook-name" --project=your-project-id

# Get metadata
gcloud secrets versions access latest --secret="github-webhook-repo-name-webhook-name-metadata" --project=your-project-id
```

### Programmatic Access (CI/CD)

Grant service accounts the `roles/secretmanager.secretAccessor` role:

```python
from google.cloud import secretmanager

client = secretmanager.SecretManagerServiceClient()
name = "projects/PROJECT_ID/secrets/github-webhook-repo-webhook/versions/latest"
response = client.access_secret_version(request={"name": name})
webhook_secret = response.payload.data.decode("UTF-8")
```

## Security Best Practices

### IAM Permissions

Restrict access to webhook secrets:

```hcl
# In your GCP configuration
resource "google_secret_manager_secret_iam_member" "webhook_secret_accessor" {
  secret_id = "github-webhook-*"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:ci-cd@project.iam.gserviceaccount.com"
}
```

### Audit Logging

Enable audit logs for Secret Manager:

```hcl
resource "google_project_iam_audit_config" "secret_manager_audit" {
  project = var.gcp_project_name
  service = "secretmanager.googleapis.com"
  
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  
  audit_log_config {
    log_type = "DATA_READ"
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}
```

### Monitoring

Set up alerts for secret access:

```bash
# Alert on secret access
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="Webhook Secret Access" \
  --condition-display-name="Secret accessed" \
  --condition-threshold-value=1 \
  --condition-threshold-duration=0s \
  --condition-filter='resource.type="secret_manager_secret" AND protoPayload.methodName="google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion"'
```

## Troubleshooting

### Secret Not Found

**Problem**: Webhook secret not found in Secret Manager

**Solution**:
```bash
# Check if Secret Manager API is enabled
gcloud services list --enabled --project=your-project-id | grep secretmanager

# Enable if needed
gcloud services enable secretmanager.googleapis.com --project=your-project-id

# Re-run terraform
terraform apply
```

### Webhook Authentication Fails

**Problem**: GitHub webhook returns 401/403

**Causes**:
1. Secret not yet propagated to GitHub
2. Wrong secret being used
3. Rotation in progress

**Solution**:
```bash
# Verify secret in Secret Manager
gcloud secrets versions access latest --secret="github-webhook-REPO-WEBHOOK" --project=your-project-id

# Check GitHub webhook configuration
# Go to GitHub repo → Settings → Webhooks → Edit webhook
# Verify the secret matches
```

### Rotation Not Happening

**Problem**: Secrets not rotating after N days

**Check**:
```bash
# View rotation timestamps
terraform output webhook_rotation_timestamps

# Check time_rotating resource
terraform state show 'component.webhook-secret-manager.time_rotating.webhook_secret_rotation["repo-webhook"]'
```

**Solution**: Apply terraform to trigger rotation:
```bash
terraform apply
```

## Migration from Existing Webhooks

If you have existing webhooks with manual secrets:

### Option 1: Import and Migrate

```bash
# 1. Let Terraform create new secrets
terraform apply

# 2. Manually update your webhook consumers to use new secrets from Secret Manager
# 3. Remove old secrets from your webhook configuration
```

### Option 2: One-time Import

```hcl
# Temporarily store existing secret in terraform (NOT RECOMMENDED for long-term)
github_repositories = {
  "existing-repo" = {
    webhooks = {
      "existing-webhook" = {
        url    = "https://example.com/webhook"
        secret = var.temporary_existing_secret  # Use temporarily
        events = ["push"]
      }
    }
  }
}

# Then remove 'secret' field and let auto-generation take over on next apply
```

## Cost Considerations

### GCP Secret Manager Pricing

- **Secret versions**: $0.06 per secret per month
- **API calls**: $0.03 per 10,000 operations
- **Rotation**: Creates 1 new version per rotation period

### Example Cost

For 10 webhooks with 90-day rotation:
- Storage: 10 secrets × $0.06 = $0.60/month
- Rotation: 10 × (365/90) = ~41 rotations/year
- API calls: Minimal (mostly during terraform apply)

**Total**: ~$7.20/year for 10 webhook secrets

## Advanced Configuration

### Per-Webhook Rotation Periods

Each webhook can have its own rotation period. This is useful when different webhooks have different security requirements:

```hcl
github_repositories = {
  "secure-app" = {
    webhooks = {
      # High-security webhook - rotate frequently
      "security-scanner" = {
        url           = "https://security.example.com/webhook"
        events        = ["push", "pull_request"]
        rotation_days = 7  # Weekly rotation for maximum security
      }
      
      # CI/CD webhook - moderate rotation
      "ci-cd" = {
        url           = "https://ci.example.com/webhook"
        events        = ["push", "pull_request", "release"]
        rotation_days = 30  # Monthly rotation
      }
      
      # Notification webhook - infrequent rotation
      "notifications" = {
        url           = "https://slack.example.com/webhook"
        events        = ["issues", "pull_request"]
        rotation_days = 365  # Yearly rotation
      }
      
      # Default rotation webhook
      "monitoring" = {
        url    = "https://monitor.example.com/webhook"
        events = ["deployment"]
        # Uses global default (90 days)
      }
    }
  }
}
```

### Rotation Period Guidelines

| Use Case | Recommended Period | Reason |
|----------|-------------------|--------|
| Security/Compliance | 7-14 days | High sensitivity, frequent rotation |
| CI/CD Systems | 30-60 days | Balance security and stability |
| Monitoring/Alerting | 90-180 days | Lower risk, stability preferred |
| Notifications | 180-365 days | Low risk, minimal changes |

### Custom Secret Length

Modify `modules/webhook-secret-manager/variables.tf`:

```hcl
variable "secret_length" {
  description = "Length of generated webhook secrets"
  type        = number
  default     = 64  # Increase for higher entropy
}
```

### Regional Secrets

Modify `modules/webhook-secret-manager/main.tf`:

```hcl
resource "google_secret_manager_secret" "webhook_secret" {
  # ...
  
  replication {
    user_managed {
      replicas {
        location = "us-central1"
      }
      replicas {
        location = "europe-west1"
      }
    }
  }
}
```

## References

- [GCP Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [GitHub Webhook Security](https://docs.github.com/en/webhooks/securing-webhooks)
- [Terraform time_rotating Resource](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating)
- [Terraform random_password Resource](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)

