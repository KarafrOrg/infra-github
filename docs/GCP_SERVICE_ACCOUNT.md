# GCP Service Account Configuration

This document describes the required GCP service account configuration for webhook secret management.

## Service Account Specification

The following service account should be created in your GCP project for Terraform to manage webhook secrets:

```hcl
"terraform-webhook-manager" = {
  display_name = "Terraform Webhook Secret Manager"
  description  = "Service account for managing GitHub webhook secrets in Secret Manager"
  roles = [
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountTokenCreator"
  ]
}
```

**Note**: The `roles/iam.serviceAccountTokenCreator` role is required when using Workload Identity Federation to allow Terraform Cloud to impersonate the service account.

## Required IAM Roles

### roles/secretmanager.admin

This role provides complete control over Secret Manager resources and is required for the webhook secret management functionality.

**Permissions Included**:
- Create, read, update, and delete secrets
- Create, read, and delete secret versions
- Manage IAM policies on secrets
- List secrets and versions

**Why Required**:
- **Secret Creation**: Create new secrets for each webhook
- **Version Management**: Add new versions during rotation
- **Secret Deletion**: Remove secrets when repositories or webhooks are destroyed
- **Label Management**: Update secret labels with rotation metadata
- **Lifecycle Management**: Complete control over secret lifecycle

### roles/iam.serviceAccountTokenCreator

This role provides the ability to impersonate the service account when using Workload Identity Federation.

**Permissions Included**:
- `iam.serviceAccounts.getAccessToken`
- `iam.serviceAccounts.implicitDelegation`

**Why Required**:
- Enables Terraform Cloud to obtain access tokens for the service account
- Required for Workload Identity Federation authentication flow
- Allows token generation without service account keys

## Alternative: Granular Roles

Google Cloud does not provide a combination of predefined roles that offers the same functionality as `secretmanager.admin` without over-privileging. The available predefined roles are:

| Role | Permissions | Sufficient |
|------|-------------|------------|
| `roles/secretmanager.admin` | Full control | Yes |
| `roles/secretmanager.secretAccessor` | Read secret values only | No |
| `roles/secretmanager.secretVersionManager` | Manage versions only | No |
| `roles/secretmanager.viewer` | Read metadata only | No |

For custom role creation, see [Custom IAM Roles](#custom-iam-roles).

## Service Account Creation

### Using gcloud CLI

```bash
# Create service account
gcloud iam service-accounts create terraform-webhook-manager \
  --display-name="Terraform Webhook Secret Manager" \
  --description="Service account for managing GitHub webhook secrets in Secret Manager" \
  --project=PROJECT_ID

# Assign required roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

### Using Terraform

```hcl
resource "google_service_account" "terraform_webhook_manager" {
  account_id   = "terraform-webhook-manager"
  display_name = "Terraform Webhook Secret Manager"
  description  = "Service account for managing GitHub webhook secrets in Secret Manager"
  project      = var.gcp_project_name
}

resource "google_project_iam_member" "terraform_webhook_manager_secretmanager" {
  project = var.gcp_project_name
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.terraform_webhook_manager.email}"
}

resource "google_project_iam_member" "terraform_webhook_manager_token_creator" {
  project = var.gcp_project_name
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.terraform_webhook_manager.email}"
}
```

## Workload Identity Configuration

For Terraform Cloud deployments, configure Workload Identity Federation:

### 1. Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create terraform-cloud \
  --location="global" \
  --description="Terraform Cloud Workload Identity Pool" \
  --project=PROJECT_ID
```

### 2. Create OIDC Provider

```bash
gcloud iam workload-identity-pools providers create-oidc terraform-cloud \
  --location="global" \
  --workload-identity-pool="terraform-cloud" \
  --issuer-uri="https://app.terraform.io" \
  --attribute-mapping="google.subject=assertion.sub" \
  --project=PROJECT_ID
```

### 3. Grant Workload Identity User Role

```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/terraform-cloud/*" \
  --project=PROJECT_ID
```

### 4. Configure Terraform Cloud

Add to `deployments.tfdeploy.hcl`:

```hcl
identity_token "gcp" {
  audience = [
    "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
  ]
}

deployment "production" {
  inputs = {
    gcp_identity_token        = identity_token.gcp.jwt
    gcp_audience              = "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/terraform-cloud/providers/terraform-cloud"
    gcp_service_account_email = "terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com"
  }
}
```

## Security Constraints

### Resource-Level Restrictions

Restrict the service account to only manage webhook-related secrets:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin" \
  --condition='expression=resource.name.startsWith("projects/PROJECT_ID/secrets/github-webhook-"),title=webhook-secrets-only,description=Restrict to webhook secrets only'
```

### Audit Logging

Enable audit logging for Secret Manager operations:

```bash
gcloud projects get-iam-policy PROJECT_ID \
  --format=json > policy.json

# Edit policy.json to add audit config
cat >> policy.json << 'EOF'
{
  "auditConfigs": [
    {
      "service": "secretmanager.googleapis.com",
      "auditLogConfigs": [
        {
          "logType": "ADMIN_READ"
        },
        {
          "logType": "DATA_READ"
        },
        {
          "logType": "DATA_WRITE"
        }
      ]
    }
  ]
}
EOF

gcloud projects set-iam-policy PROJECT_ID policy.json
```

## Permission Verification

### Test Service Account Permissions

```bash
# Test secret creation
gcloud secrets create test-terraform-webhook \
  --data-file=- <<< "test-value" \
  --impersonate-service-account=terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID

# Test secret access
gcloud secrets versions access latest \
  --secret=test-terraform-webhook \
  --impersonate-service-account=terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID

# Test secret update
gcloud secrets update test-terraform-webhook \
  --update-labels=test=true \
  --impersonate-service-account=terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID

# Test secret deletion
gcloud secrets delete test-terraform-webhook \
  --quiet \
  --impersonate-service-account=terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID
```

### Verify IAM Bindings

```bash
# List all IAM policies for the service account
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"
```

## Custom IAM Roles

For environments requiring precise permission control, create a custom role with only the necessary permissions:

### Create Custom Role

```bash
gcloud iam roles create terraformWebhookSecretManager \
  --project=PROJECT_ID \
  --title="Terraform Webhook Secret Manager" \
  --description="Custom role for managing GitHub webhook secrets" \
  --stage=GA \
  --permissions="\
secretmanager.secrets.create,\
secretmanager.secrets.delete,\
secretmanager.secrets.get,\
secretmanager.secrets.getIamPolicy,\
secretmanager.secrets.list,\
secretmanager.secrets.setIamPolicy,\
secretmanager.secrets.update,\
secretmanager.versions.access,\
secretmanager.versions.add,\
secretmanager.versions.destroy,\
secretmanager.versions.disable,\
secretmanager.versions.enable,\
secretmanager.versions.get,\
secretmanager.versions.list,\
serviceusage.services.enable,\
serviceusage.services.get,\
serviceusage.services.list"
```

### Assign Custom Role

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="projects/PROJECT_ID/roles/terraformWebhookSecretManager"
```

### Custom Role Configuration Format

```hcl
"terraform-webhook-manager" = {
  display_name = "Terraform Webhook Secret Manager"
  description  = "Service account for managing GitHub webhook secrets in Secret Manager"
  roles = [
    "projects/PROJECT_ID/roles/terraformWebhookSecretManager"
  ]
}
```

## Additional Service Account Roles

If your deployment includes additional GCP integrations beyond webhook secrets, consider adding:

```hcl
"terraform-webhook-manager" = {
  display_name = "Terraform Webhook Secret Manager"
  description  = "Service account for managing GitHub webhook secrets in Secret Manager"
  roles = [
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountViewer"  # If service account inspection is needed
  ]
}
```

## Terraform Cloud Variable Configuration

Store the service account email in Terraform Cloud variable set:

**Variable Set**: `infra-github-variables`

**Variables**:
- `gcp_service_account_email`: `terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com`
- `github_token`: GitHub Personal Access Token (sensitive)

## Summary

The service account requires `roles/secretmanager.admin` to manage webhook secrets throughout their lifecycle. This includes:

- Creating secrets during initial repository deployment
- Adding new secret versions during rotation
- Updating secret metadata and labels
- Deleting secrets when resources are destroyed
- Managing secret version lifecycle

For homelab environments, the standard `roles/secretmanager.admin` role provides appropriate permissions without requiring custom role management.

