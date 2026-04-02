# Troubleshooting Common Errors

This document provides solutions for common errors encountered during deployment and operations.

## GitHub API Errors

### Error: 422 PATCH Organization Settings

**Error Message**:
```
Error: PATCH https://api.github.com/orgs/ORG_NAME: 422 []
on modules/github-organization/main.tf line 1, in resource "github_organization_settings" "organization"
```

**Cause**: Attempting to set organization fields that cannot be modified or are not available for your organization type.

**Resolution**:

The organization module includes a lifecycle block that ignores changes to certain fields:
- `blog`
- `email`
- `twitter_username`
- `location`
- `name`
- `description`

These fields may be read-only for your organization. The configuration will ignore external changes to these fields.

**Additional Steps**:
1. Verify your GitHub token has `admin:org` scope
2. Confirm you have owner permissions on the organization
3. Check if the organization is enterprise-managed (may have restrictions)

## GCP Authentication Errors

### Error: Permission 'iam.serviceAccounts.getAccessToken' Denied

**Error Message**:
```
Error: Request `List Project Services` returned error: Get "https://serviceusage.googleapis.com/...": 
oauth2/google: status code 403: {
  "error": {
    "code": 403,
    "message": "Permission 'iam.serviceAccounts.getAccessToken' denied on resource"
  }
}
```

**Cause**: The service account configured for Workload Identity Federation lacks the required permission to generate access tokens.

**Resolution**:

The service account requires the `roles/iam.serviceAccountTokenCreator` role in addition to `roles/secretmanager.admin`.

**Complete Service Account Configuration**:
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

**Grant Role via gcloud**:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

**Alternative**: Grant at the service account level (more restrictive):
```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/terraform-cloud/*" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=PROJECT_ID
```

### Error: Missing Workload Identity User Binding

**Error Message**:
```
Error: Permission denied on Workload Identity Federation
```

**Cause**: The Terraform Cloud workload identity principal lacks permission to impersonate the service account.

**Resolution**:
```bash
gcloud iam service-accounts add-iam-policy-binding \
  terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/terraform-cloud/*" \
  --project=PROJECT_ID
```

## Webhook Secret Manager Errors

### Error: Missing Attribute Configuration (time_rotating)

**Error Message**:
```
Error: Missing Attribute Configuration
At least one of these attributes must be configured: [rotation_days,...]
on modules/webhook-secret-manager/main.tf line 11, in resource "time_rotating" "webhook_secret_rotation"
```

**Cause**: The `rotation_days` value is null or not provided for a webhook configuration.

**Resolution**:

This has been fixed in the module by using `coalesce` to provide a default value:
```hcl
rotation_days = coalesce(each.value.rotation_days, 90)
```

**Verification**: Ensure all webhooks either:
- Specify `rotation_days` explicitly, OR
- Global `webhook_secret_rotation_days` is set in deployment

### Error: Operation Failed (timeadd with null)

**Error Message**:
```
Error: Operation failed
Error during operation: argument must not be null
on modules/webhook-secret-manager/main.tf line 95, next_rotation = timeadd(...)
```

**Cause**: The `rotation_days` value is null when calculating next rotation time.

**Resolution**:

This has been fixed by using `coalesce` in the metadata calculation:
```hcl
next_rotation = timeadd(timestamp(), "${coalesce(each.value.rotation_days, 90) * 24}h")
```

## Terraform State Errors

### Error: State Lock Acquisition Failed

**Error Message**:
```
Error: Error acquiring the state lock
```

**Cause**: Another Terraform process is running or a previous run did not release the lock.

**Resolution**:
1. Wait for concurrent operation to complete
2. If lock is stuck (previous run crashed):
```bash
terraform force-unlock LOCK_ID
```

**Prevention**: Ensure only one Terraform process runs at a time.

### Error: State Drift Detected

**Error Message**:
```
Error: Resource has been modified outside of Terraform
```

**Cause**: Resources were manually modified in GitHub UI or via API.

**Resolution**:
```bash
# Refresh state to sync
terraform refresh

# Review differences
terraform plan

# Apply to reconcile or import changes
terraform apply
```

## Resource Import Errors

### Error: Resource Already Exists

**Error Message**:
```
Error: POST https://api.github.com/orgs/ORG/repos: 422 name already exists
```

**Cause**: Repository already exists in GitHub.

**Resolution**:
```bash
# Import existing repository
terraform import 'component.github-repositories["repo-name"].github_repository.repository' repository-name

# Re-run plan
terraform plan
```

### Error: Team Already Exists

**Error Message**:
```
Error: error creating GitHub Team: Team name already taken
```

**Resolution**:
```bash
# Import existing team using team slug
terraform import 'component.github-teams["team-name"].github_team.team' team-slug

# Re-run apply
terraform apply
```

## GitHub Provider Errors

### Error: Rate Limit Exceeded

**Error Message**:
```
Error: GET https://api.github.com/...: 403 API rate limit exceeded
```

**Cause**: Exceeded GitHub API rate limits.

**Resolution**:
1. Wait for rate limit window to reset (typically 1 hour)
2. Reduce number of resources created in single apply
3. Consider using GitHub App authentication (higher rate limits)

### Error: Resource Not Accessible

**Error Message**:
```
Error: Resource not accessible by personal access token
```

**Cause**: Operation requires GitHub App authentication or different permissions.

**Resolution**:
1. Verify token has required scopes
2. Check organization settings allow the operation
3. Consider using GitHub App instead of Personal Access Token

## Secret Manager Errors

### Error: API Not Enabled

**Error Message**:
```
Error 403: Secret Manager API has not been used in project PROJECT_ID
```

**Resolution**:
```bash
gcloud services enable secretmanager.googleapis.com --project=PROJECT_ID
gcloud services enable serviceusage.googleapis.com --project=PROJECT_ID
```

### Error: Insufficient Permissions

**Error Message**:
```
Error: Permission 'secretmanager.secrets.create' denied
```

**Resolution**:

Verify the service account has the required roles:
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --format="table(bindings.role)"
```

Should show:
- `roles/secretmanager.admin`
- `roles/iam.serviceAccountTokenCreator`

If missing, grant the roles:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/secretmanager.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform-webhook-manager@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

## Component Dependency Errors

### Error: Invalid Index (Team ID Not Found)

**Error Message**:
```
Error: Invalid index: The given key does not identify an element in this collection value
```

**Cause**: Attempting to reference a team that hasn't been created yet.

**Resolution**:

Verify component dependencies in `components.tfcomponent.hcl`:
```hcl
component "github-repositories" {
  depends_on = [
    component.github-teams,
    component.webhook-secret-manager
  ]
}
```

### Error: Output Not Available

**Error Message**:
```
Error: Reference to undeclared output value
```

**Cause**: Attempting to reference an output that doesn't exist or hasn't been created.

**Resolution**:
1. Verify the component exists
2. Check the output is defined in the module's outputs.tf
3. Ensure dependencies are properly configured

## Validation Errors

### Error: Validation Failed

**Error Message**:
```
Error: Invalid value for variable
Value must be one of: [...]
```

**Cause**: Variable value doesn't match validation constraints.

**Resolution**:

Review variable constraints in `variables.tfcomponent.hcl` and ensure values match:

**Example - Repository Visibility**:
```hcl
visibility = "private"  # Must be: public, private, or internal
```

**Example - Team Privacy**:
```hcl
privacy = "closed"  # Must be: secret or closed
```

**Example - Repository Permission**:
```hcl
team_permissions = {
  "team" = "admin"  # Must be: pull, triage, push, maintain, or admin
}
```

## Network Errors

### Error: Connection Timeout

**Error Message**:
```
Error: Get "https://api.github.com/...": dial tcp: i/o timeout
```

**Cause**: Network connectivity issues.

**Resolution**:
1. Verify internet connectivity
2. Check firewall rules
3. Verify GitHub API is accessible
4. Retry the operation

## Configuration Syntax Errors

### Error: Invalid HCL Syntax

**Error Message**:
```
Error: Invalid expression
```

**Cause**: Syntax error in configuration files.

**Resolution**:
```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Check specific file
terraform fmt -check components.tfcomponent.hcl
```

## Debugging Steps

### General Debugging Process

1. **Enable Debug Logging**:
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terraform apply
```

2. **Review Error Output**:
- Read complete error message
- Note the resource causing the error
- Identify the line number in the file

3. **Check Resource State**:
```bash
terraform state show 'component.NAME.resource.TYPE.NAME'
```

4. **Verify Providers**:
```bash
terraform providers
```

5. **Validate Configuration**:
```bash
terraform validate
```

### Component-Specific Debugging

**Organization Component**:
```bash
# Check current organization settings
curl -H "Authorization: token GITHUB_TOKEN" \
  https://api.github.com/orgs/ORG_NAME

# Verify token scopes
curl -H "Authorization: token GITHUB_TOKEN" \
  -I https://api.github.com/user
```

**Secret Manager Component**:
```bash
# List secrets
gcloud secrets list \
  --filter="labels.type=github-webhook" \
  --project=PROJECT_ID

# Check API status
gcloud services list --enabled --project=PROJECT_ID | grep secretmanager
```

**Team Component**:
```bash
# List existing teams
curl -H "Authorization: token GITHUB_TOKEN" \
  https://api.github.com/orgs/ORG_NAME/teams
```

## Recovery Procedures

### State Corruption

If state becomes corrupted:

1. **Backup current state**:
```bash
terraform state pull > backup.tfstate
```

2. **Remove problematic resource**:
```bash
terraform state rm 'component.NAME.resource.TYPE.NAME'
```

3. **Re-import resource**:
```bash
terraform import 'component.NAME.resource.TYPE.NAME' RESOURCE_ID
```

### Complete Infrastructure Reset

If infrastructure requires complete rebuild:

1. **Export current state for reference**:
```bash
terraform state pull > pre-destroy-state.json
```

2. **Destroy infrastructure**:
```bash
terraform destroy
```

3. **Re-initialize**:
```bash
terraform init -reconfigure
```

4. **Re-apply**:
```bash
terraform apply
```

## Reference Documentation

- GitHub Provider: https://registry.terraform.io/providers/integrations/github/latest/docs
- Google Provider: https://registry.terraform.io/providers/hashicorp/google/latest/docs
- Terraform Stacks: https://developer.hashicorp.com/terraform/language/stacks
- GCP Secret Manager: https://cloud.google.com/secret-manager/docs
- Workload Identity Federation: https://cloud.google.com/iam/docs/workload-identity-federation

