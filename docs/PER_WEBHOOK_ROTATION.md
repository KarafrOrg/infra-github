# Per-Webhook Rotation Implementation

## Summary

Successfully implemented **individual rotation periods for each webhook secret**. Each webhook can now have its own `rotation_days` configuration, allowing fine-grained control over security policies.

---

## ✅ Changes Made

### 1. Updated Variable Definitions

**File**: `variables.tfcomponent.hcl`

Added `rotation_days` field to webhook object:

```hcl
webhooks = optional(map(object({
  url           = string
  content_type  = optional(string, "json")
  events        = list(string)
  active        = optional(bool, true)
  rotation_days = optional(number, null) # NEW: Per-webhook rotation period
})), {})
```

### 2. Updated Webhook Secret Manager Module

**Files**: 
- `modules/webhook-secret-manager/variables.tf`
- `modules/webhook-secret-manager/main.tf`

**Changes**:
- Added `rotation_days` to webhook_configs object
- Removed global `rotation_days` variable (now per-webhook)
- Updated rotation triggers to use individual rotation periods
- Updated Secret Manager labels with per-webhook rotation days
- Updated metadata JSON with individual rotation schedules

### 3. Updated Components Logic

**File**: `components.tfcomponent.hcl`

Enhanced webhook secret manager to:
- Extract `rotation_days` from each webhook config
- Fall back to global default if not specified
- Pass individual rotation period to secret manager

```hcl
webhook_configs = merge([
  for repo_name, repo_config in var.github_repositories : {
    for webhook_name, webhook_config in try(repo_config.webhooks, {}) :
    "${repo_name}-${webhook_name}" => {
      repository_name = repo_name
      webhook_name    = webhook_name
      url             = webhook_config.url
      # Use webhook-specific rotation_days if set, otherwise use global default
      rotation_days   = try(webhook_config.rotation_days, var.webhook_secret_rotation_days)
    }
  }
]...)
```

### 4. Updated Example Configuration

**File**: `deployments.tfdeploy.hcl`

Added example showing different rotation periods:

```hcl
webhooks = {
  "ci-webhook" = {
    url           = "https://ci.example.com/webhook"
    events        = ["push", "pull_request"]
    rotation_days = 30  # Rotate every 30 days
  }
  "slack-webhook" = {
    url           = "https://hooks.slack.com/services/..."
    events        = ["push", "issues", "pull_request"]
    rotation_days = 180  # Rotate every 180 days
  }
  "monitoring-webhook" = {
    url    = "https://monitoring.example.com/webhook"
    events = ["push", "release"]
    # No rotation_days - uses global default (90 days)
  }
}
```

### 5. Updated Documentation

**Files Updated**:
- `docs/WEBHOOK_SECRETS.md` - Added per-webhook rotation section with guidelines
- `docs/QUICK_START.md` - Added rotation_days example
- `docs/EXAMPLES.md` - Updated examples with varying rotation periods

---

## 🎯 How It Works

### Rotation Period Hierarchy

1. **Webhook-Specific**: If `rotation_days` is set on the webhook → use that value
2. **Global Default**: If not set → use `webhook_secret_rotation_days` (default: 90)

### Example Configurations

#### Mixed Rotation Periods

```hcl
deployment "production" {
  inputs = {
    # Global default
    webhook_secret_rotation_days = 90
    
    github_repositories = {
      "api-service" = {
        webhooks = {
          # High-security webhook - rotate weekly
          "security-scan" = {
            url           = "https://security.example.com/webhook"
            events        = ["push", "pull_request"]
            rotation_days = 7  # Every 7 days
          }
          
          # CI/CD webhook - rotate monthly
          "jenkins" = {
            url           = "https://jenkins.example.com/webhook"
            events        = ["push", "pull_request"]
            rotation_days = 30  # Every 30 days
          }
          
          # Monitoring - use default
          "datadog" = {
            url    = "https://datadog.example.com/webhook"
            events = ["deployment"]
            # Uses global default: 90 days
          }
          
          # Notifications - rotate yearly
          "slack" = {
            url           = "https://hooks.slack.com/services/..."
            events        = ["issues", "pull_request"]
            rotation_days = 365  # Every 365 days
          }
        }
      }
    }
  }
}
```

---

## 📊 Rotation Guidelines

| Webhook Type | Recommended Rotation | Reason |
|--------------|---------------------|--------|
| Security/Compliance | **7-14 days** | High sensitivity, frequent rotation required |
| CI/CD Systems | **30-60 days** | Balance security and operational stability |
| Monitoring/Alerting | **90-180 days** | Lower risk, prefer stability |
| Notifications | **180-365 days** | Minimal security risk |
| Internal Tools | **90 days** | Standard default |

---

## 🔍 Verification

After applying, you can verify different rotation periods:

### Check Rotation Timestamps

```bash
# View all webhook rotation schedules
terraform output webhook_rotation_timestamps
```

Output example:
```json
{
  "api-service-security-scan": "2026-04-09T10:00:00Z",    # 7 days from now
  "api-service-jenkins": "2026-05-02T10:00:00Z",          # 30 days from now
  "api-service-datadog": "2026-07-01T10:00:00Z",          # 90 days from now
  "api-service-slack": "2027-04-02T10:00:00Z"             # 365 days from now
}
```

### Check Secret Manager Labels

```bash
# Find secrets with 7-day rotation
gcloud secrets list --filter="labels.rotation_days=7"

# Find secrets with 30-day rotation
gcloud secrets list --filter="labels.rotation_days=30"

# Find secrets with 90-day rotation
gcloud secrets list --filter="labels.rotation_days=90"
```

### View Metadata

```bash
# Get metadata for a specific webhook
gcloud secrets versions access latest \
  --secret="github-webhook-api-service-jenkins-metadata" | jq

# Output includes rotation_days and next_rotation
{
  "repository": "api-service",
  "webhook_name": "jenkins",
  "webhook_url": "https://jenkins.example.com/webhook",
  "created_at": "2026-04-02T10:00:00Z",
  "rotation_days": 30,
  "next_rotation": "2026-05-02T10:00:00Z",
  "secret_id": "github-webhook-api-service-jenkins"
}
```

---

## 🎨 Usage Examples

### Example 1: Security-First Repository

```hcl
"secure-app" = {
  description = "High-security application"
  
  webhooks = {
    # Aggressive rotation for security webhooks
    "security-scanner" = {
      url           = "https://security.company.com/webhook"
      events        = ["push", "pull_request", "secret_scanning_alert"]
      rotation_days = 7  # Weekly rotation
    }
    
    # Standard rotation for CI/CD
    "ci-cd" = {
      url           = "https://ci.company.com/webhook"
      events        = ["push", "pull_request"]
      rotation_days = 30  # Monthly rotation
    }
  }
}
```

### Example 2: Low-Risk Repository

```hcl
"documentation" = {
  description = "Documentation repository"
  
  webhooks = {
    # Infrequent rotation for low-risk webhooks
    "netlify-deploy" = {
      url           = "https://netlify.com/webhook"
      events        = ["push"]
      rotation_days = 365  # Yearly rotation
    }
    
    "docs-notifications" = {
      url           = "https://slack.com/webhook"
      events        = ["push", "pull_request"]
      rotation_days = 180  # Semi-annual rotation
    }
  }
}
```

### Example 3: Mixed Environment

```hcl
"monorepo" = {
  description = "Monorepo with multiple integrations"
  
  webhooks = {
    # Production deployment - strict rotation
    "prod-deploy" = {
      url           = "https://prod-deploy.company.com/webhook"
      events        = ["release", "deployment"]
      rotation_days = 14  # Bi-weekly rotation
    }
    
    # Development CI - moderate rotation
    "dev-ci" = {
      url           = "https://dev-ci.company.com/webhook"
      events        = ["push", "pull_request"]
      rotation_days = 60  # Bi-monthly rotation
    }
    
    # Notifications - relaxed rotation
    "team-notifications" = {
      url           = "https://slack.com/webhook"
      events        = ["issues", "pull_request_review"]
      rotation_days = 180  # Semi-annual rotation
    }
    
    # Analytics - use default
    "analytics" = {
      url    = "https://analytics.company.com/webhook"
      events = ["push", "star"]
      # Uses global default: 90 days
    }
  }
}
```

---

## 🔄 Migration from Global Rotation

If you already have webhooks with global rotation:

### Before (Global Only)

```hcl
# Global setting for all webhooks
webhook_secret_rotation_days = 90

github_repositories = {
  "my-repo" = {
    webhooks = {
      "webhook1" = {
        url    = "https://example.com/webhook"
        events = ["push"]
        # All webhooks rotate every 90 days
      }
    }
  }
}
```

### After (Per-Webhook Control)

```hcl
# Global default (fallback)
webhook_secret_rotation_days = 90

github_repositories = {
  "my-repo" = {
    webhooks = {
      # Override for specific webhook
      "webhook1" = {
        url           = "https://example.com/webhook"
        events        = ["push"]
        rotation_days = 30  # This one rotates every 30 days
      }
      
      # Use default
      "webhook2" = {
        url    = "https://example.com/webhook2"
        events = ["pull_request"]
        # No rotation_days specified - uses global default (90 days)
      }
    }
  }
}
```

### Migration Steps

1. **No Breaking Changes**: Existing configurations without `rotation_days` continue using global default
2. **Add Per-Webhook Rotation**: Add `rotation_days` to webhooks that need different periods
3. **Apply Changes**: Run `terraform apply`
4. **Verify**: Check rotation timestamps in outputs

---

## 💡 Best Practices

### 1. Match Rotation to Risk Level

```hcl
# High-risk integrations: 7-30 days
"security-webhook" = { rotation_days = 14 }

# Medium-risk integrations: 30-90 days
"ci-cd-webhook" = { rotation_days = 60 }

# Low-risk integrations: 90-365 days
"notification-webhook" = { rotation_days = 180 }
```

### 2. Consider Operational Impact

- **Too Frequent**: May cause operational overhead, secret sync issues
- **Too Infrequent**: Reduces security benefit of rotation
- **Sweet Spot**: Balance security requirements with operational stability

### 3. Document Rotation Policies

Add comments explaining rotation choices:

```hcl
webhooks = {
  "prod-deploy" = {
    url           = "https://deploy.company.com/webhook"
    events        = ["deployment"]
    rotation_days = 30  # Monthly rotation per security policy SEC-001
  }
}
```

### 4. Monitor Rotation Events

Set up alerts for:
- Failed rotations
- Upcoming rotations
- Secrets nearing expiration

---

## 🎉 Benefits

✅ **Granular Control**: Different rotation periods per webhook  
✅ **Security Compliance**: Meet different compliance requirements  
✅ **Operational Flexibility**: Balance security vs. stability per use case  
✅ **Backward Compatible**: Existing configs work without changes  
✅ **Easy Migration**: Simple opt-in per webhook  
✅ **Full Transparency**: Rotation schedules visible in Secret Manager  

---

## Files Modified

1. ✅ `variables.tfcomponent.hcl` - Added rotation_days to webhook object
2. ✅ `modules/webhook-secret-manager/variables.tf` - Updated webhook_configs type
3. ✅ `modules/webhook-secret-manager/main.tf` - Individual rotation triggers
4. ✅ `components.tfcomponent.hcl` - Pass rotation_days with fallback
5. ✅ `deployments.tfdeploy.hcl` - Added examples
6. ✅ `docs/WEBHOOK_SECRETS.md` - Added per-webhook rotation guide
7. ✅ `docs/QUICK_START.md` - Added rotation_days example
8. ✅ `docs/EXAMPLES.md` - Updated examples

---

**You can now configure rotation periods individually for each webhook based on your security requirements!** 🎯

