# Deployment Guide

This guide provides step-by-step instructions for deploying and managing the GCP infrastructure using Terraform Stacks.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Authentication Setup](#authentication-setup)
- [Step-by-Step Deployment](#step-by-step-deployment)
- [Verification](#verification)
- [Operations](#operations)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- **Terraform**: Version 1.9.0 or higher
  ```bash
  terraform version
  ```

- **kubectl**: For Kubernetes operations
  ```bash
  kubectl version --client
  ```

- **gcloud CLI**: For GCP operations
  ```bash
  gcloud version
  ```

### Required Accounts and Access

- **GCP Project**: Active GCP project with billing enabled
- **Terraform Cloud**: Account with appropriate workspace permissions
- **Kubernetes Cluster**: Running cluster with API access
- **IAM Permissions**: Sufficient permissions to create service accounts and IAM bindings

### Required APIs

The following GCP APIs must be enabled:

- Identity and Access Management (IAM) API
- Service Usage API
- Cloud Resource Manager API
- IAM Service Account Credentials API
- Security Token Service API
- Secret Manager API (enabled automatically by the stack)
- Kubernetes Engine API (if using GKE)

Enable APIs:
```bash
gcloud services enable iam.googleapis.com \
  serviceusage.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  --project=YOUR_PROJECT_ID
```

## Authentication Setup

### Terraform Cloud Workload Identity Federation

This stack uses Workload Identity Federation for Terraform Cloud to authenticate to GCP.

#### 1. Create Workload Identity Pool (One-time setup)

```bash
# Set variables
export PROJECT_ID="your-project-id"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')
export POOL_NAME="terraform-cloud"
export PROVIDER_NAME="terraform-cloud"
export TFC_ORG="your-tfc-org"

# Create workload identity pool
gcloud iam workload-identity-pools create ${POOL_NAME} \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="Terraform Cloud"

# Create workload identity provider
gcloud iam workload-identity-pools providers create-oidc ${PROVIDER_NAME} \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_NAME}" \
  --display-name="Terraform Cloud" \
  --attribute-mapping="google.subject=assertion.sub,attribute.aud=assertion.aud,attribute.terraform_organization_id=assertion.terraform_organization_id" \
  --issuer-uri="https://app.terraform.io" \
  --allowed-audiences="https://app.terraform.io"
```

#### 2. Create Service Account for Terraform

```bash
# Create service account
gcloud iam service-accounts create terraform-cloud \
  --display-name="Terraform Cloud Service Account" \
  --project="${PROJECT_ID}"

# Grant necessary permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:terraform-cloud@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:terraform-cloud@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"
```

#### 3. Configure Workload Identity Binding

```bash
# Allow Terraform Cloud to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  terraform-cloud@${PROJECT_ID}.iam.gserviceaccount.com \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.terraform_organization_id/${TFC_ORG}"
```

### Kubernetes Authentication

Configure kubectl to access your Kubernetes cluster:

#### For GKE:
```bash
gcloud container clusters get-credentials CLUSTER_NAME \
  --zone=ZONE \
  --project=PROJECT_ID
```

#### For Non-GKE Clusters:
Obtain the following credentials and store them in Terraform Cloud variable set:
- `kube_host` - Kubernetes API server URL
- `kube_client_cert_data` - Base64-encoded client certificate
- `kube_client_key_data` - Base64-encoded client key
- `kube_client_ca_cert` - Base64-encoded cluster CA certificate

### Terraform Cloud Variable Set

Create a variable set named `infra-gcp-variables` with the following variables:

**Sensitive Variables:**
- `gcp_service_account_email` - Email of the Terraform service account
- `kube_host` - Kubernetes API server URL
- `kube_client_cert_data` - Kubernetes client certificate (base64)
- `kube_client_key_data` - Kubernetes client key (base64)
- `kube_client_ca_cert` - Kubernetes cluster CA certificate (base64)
- `stable.jwks_json_data` - JWKS data for OIDC validation

**Regular Variables:**
- Project-specific settings (if any)

## Step-by-Step Deployment

### 1. Clone Repository

```bash
git clone <repository-url>
cd infra-gcp
```

### 2. Review Configuration

Review the deployment configuration in `deployments.tfdeploy.hcl`:

```bash
cat deployments.tfdeploy.hcl
```

Key sections to verify:
- GCP project name and region
- Service account configurations
- Kubernetes cluster details
- Workload Identity Federation settings

### 3. Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers
- Initialize the backend
- Prepare modules

### 4. Plan Deployment

```bash
terraform plan
```

Review the plan output carefully:
- Check which resources will be created
- Verify service account permissions
- Confirm namespace and cluster configurations
- Look for any warnings or errors

### 5. Apply Configuration

```bash
terraform apply
```

When prompted:
1. Review the plan one more time
2. Type `yes` to confirm
3. Wait for deployment to complete

Expected resources:
- 4+ service accounts (depending on configuration)
- 1+ Pub/Sub topics (if secret rotation enabled)
- Workload Identity bindings
- Kubernetes service accounts

### 6. Verify Deployment

See [Verification](#verification) section below.

## Verification

### 1. Verify GCP Service Accounts

```bash
# List all service accounts in project
gcloud iam service-accounts list --project=PROJECT_ID

# Check specific service account
gcloud iam service-accounts describe k8s-admin@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID
```

Expected output should show service accounts:
- `k8s-admin`
- `k8s-secret-reader`
- `k8s-storage-admin`
- `k8s-monitoring`

### 2. Verify IAM Roles

```bash
# Check project IAM policy
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:k8s-admin@PROJECT_ID.iam.gserviceaccount.com"
```

### 3. Verify Workload Identity Bindings

```bash
# Check service account IAM policy
gcloud iam service-accounts get-iam-policy \
  k8s-admin@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID
```

Should show workload identity user bindings for Kubernetes service accounts.

### 4. Verify Kubernetes Service Accounts

```bash
# Check service accounts
kubectl get sa cluster-admin -n kube-system -o yaml
kubectl get sa default-app -n default -o yaml

# Verify annotation
kubectl get sa cluster-admin -n kube-system \
  -o jsonpath='{.metadata.annotations.iam\.gke\.io/gcp-service-account}'
```

Expected: Should show the GCP service account email in annotations.

### 5. Verify Pub/Sub Topics

```bash
# List Pub/Sub topics
gcloud pubsub topics list --project=PROJECT_ID

# Check specific topic
gcloud pubsub topics describe k8s-ca-rotation-k8s-production \
  --project=PROJECT_ID

# Check IAM policy on topic
gcloud pubsub topics get-iam-policy k8s-ca-rotation-k8s-production \
  --project=PROJECT_ID
```

### 6. Test Workload Identity

See [WORKLOAD_IDENTITY.md](WORKLOAD_IDENTITY.md) for comprehensive testing procedures.

Quick test:
```bash
# Deploy test pod
kubectl run wif-test \
  --image=google/cloud-sdk:slim \
  --namespace=default \
  --overrides='{"spec":{"serviceAccountName":"default-app"}}' \
  --command -- sleep infinity

# Test authentication
kubectl exec -it wif-test -n default -- gcloud auth list

# Clean up
kubectl delete pod wif-test -n default
```

## Operations

### Adding a New Service Account

1. Edit `deployments.tfdeploy.hcl`:
```hcl
gcp_service_service_accounts = {
  # ...existing accounts...
  "new-service-account" = {
    display_name = "New Service Account"
    description  = "Description of purpose"
    roles = [
      "roles/required.role"
    ]
  }
}
```

2. Plan and apply:
```bash
terraform plan
terraform apply
```

### Adding a New Kubernetes Service Account

1. Edit `deployments.tfdeploy.hcl` in the `k8s_clusters` section:
```hcl
kubernetes_service_accounts = {
  # ...existing accounts...
  "new-k8s-sa" = {
    namespace                 = "target-namespace"
    gcp_service_account_email = "service-account@project.iam.gserviceaccount.com"
    create_k8s_sa             = true
    k8s_sa_labels = {
      app = "myapp"
    }
  }
}
```

2. Plan and apply:
```bash
terraform plan
terraform apply
```

### Adding a New Cluster

1. Edit `deployments.tfdeploy.hcl`:
```hcl
k8s_clusters = {
  # ...existing clusters...
  "k8s-staging" = {
    issuer_uri        = "https://kubernetes.default.svc.cluster.local"
    display_name      = "k8s Staging Cluster"
    allowed_audiences = ["sts.googleapis.com"]
    jwks_json_data    = store.varset.credentials.staging.jwks_json_data
    
    kubernetes_service_accounts = {
      # Define service accounts for this cluster
    }
  }
}
```

2. Obtain JWKS data for the new cluster (see WORKLOAD_IDENTITY.md)

3. Plan and apply:
```bash
terraform plan
terraform apply
```

### Modifying Service Account Permissions

1. Edit the `roles` list for the service account in `deployments.tfdeploy.hcl`
2. Run plan to preview changes:
```bash
terraform plan
```
3. Apply changes:
```bash
terraform apply
```

### Rotating JWKS

1. Generate new JWKS from your cluster
2. Update the variable in Terraform Cloud variable set
3. Run apply:
```bash
terraform apply
```

Note: No resources need to be recreated, only updated.

### Destroying Resources

**WARNING**: This will delete all managed infrastructure.

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy
```

To destroy specific resources:
```bash
# Target specific component
terraform destroy -target=component.kubernetes-service-account
```

## Troubleshooting

### Common Issues

#### Issue: "Error 403: Kubernetes Engine API has not been used"

**Solution**: Enable the Kubernetes Engine API:
```bash
gcloud services enable container.googleapis.com --project=PROJECT_ID
```

Wait 2-3 minutes for propagation, then retry.

#### Issue: "Service account does not exist" when creating IAM bindings

**Cause**: Service agent not created yet or API not enabled.

**Solution**:
1. Ensure Secret Manager API is enabled:
```bash
gcloud services enable secretmanager.googleapis.com --project=PROJECT_ID
```

2. Wait for service agent creation (automatic)
3. Verify service agent exists:
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:service-*@gcp-sa-secretmanager.iam.gserviceaccount.com"
```

#### Issue: Workload Identity not working in pods

**Diagnosis**:
```bash
# Check service account annotation
kubectl get sa SERVICE_ACCOUNT_NAME -n NAMESPACE -o yaml

# Check IAM binding
gcloud iam service-accounts get-iam-policy \
  GCP_SA_EMAIL --project=PROJECT_ID

# Test from pod
kubectl exec -it POD_NAME -- gcloud auth list
```

**Common Causes**:
1. Missing annotation on Kubernetes service account
2. Missing IAM binding for workload identity user
3. Incorrect issuer URI or JWKS
4. Workload Identity not enabled on GKE cluster

**Solution**: See [WORKLOAD_IDENTITY.md](WORKLOAD_IDENTITY.md) for detailed troubleshooting.

#### Issue: "Invalid provider configuration"

**Cause**: Missing or incorrect provider credentials.

**Solution**:
1. Verify Terraform Cloud variable set exists and is attached to workspace
2. Check all required variables are set:
   - `gcp_service_account_email`
   - `kube_host`
   - `kube_client_cert_data`
   - `kube_client_key_data`
   - `kube_client_ca_cert`

#### Issue: Terraform state lock errors

**Cause**: Previous operation did not complete cleanly.

**Solution**:
1. Wait 5 minutes for automatic unlock
2. If persists, manually unlock:
```bash
terraform force-unlock LOCK_ID
```

Use with caution - ensure no other operations are running.

#### Issue: "Error creating PubSubTopic: googleapi: Error 409: Resource already exists"

**Cause**: Topic already exists from previous deployment.

**Solution**:
1. Import existing topic:
```bash
terraform import 'module.google-secret-manager.google_pubsub_topic.secret_rotation["CLUSTER_NAME"]' projects/PROJECT_ID/topics/TOPIC_NAME
```

2. Or delete and recreate:
```bash
gcloud pubsub topics delete TOPIC_NAME --project=PROJECT_ID
terraform apply
```

### Getting Help

1. Check resource-specific logs in GCP Console
2. Review Terraform Cloud run logs
3. Check component documentation in [COMPONENTS.md](COMPONENTS.md)
4. Review architecture in [ARCHITECTURE.md](ARCHITECTURE.md)
5. Test Workload Identity using [WORKLOAD_IDENTITY.md](WORKLOAD_IDENTITY.md)

### Debug Mode

Enable detailed logging:

```bash
# Terraform debug output
export TF_LOG=DEBUG
terraform apply

# GCP API debug
export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
export TF_LOG_PROVIDER=DEBUG
```

## Best Practices

### Before Deployment

- Review the plan output carefully
- Verify all variables are set correctly
- Ensure you have necessary permissions
- Test in a non-production environment first

### During Deployment

- Monitor the apply process
- Check for warnings or errors
- Take note of any manual steps required
- Save the Terraform output

### After Deployment

- Verify all resources were created
- Test Workload Identity functionality
- Document any deviations from plan
- Update team on changes

### Regular Maintenance

- Review service account usage monthly
- Audit IAM permissions quarterly
- Rotate JWKS periodically
- Update documentation when making changes
- Keep Terraform provider versions up to date

## Rollback Procedures

### Rolling Back Changes

1. Identify the last known good state:
```bash
terraform state list
```

2. Revert configuration files to previous version:
```bash
git checkout PREVIOUS_COMMIT -- deployments.tfdeploy.hcl
```

3. Plan and apply:
```bash
terraform plan
terraform apply
```

### Emergency Rollback

If deployment fails critically:

1. Review the error in Terraform Cloud
2. If resources are partially created, let Terraform clean up:
```bash
terraform apply
```

3. If apply fails, manually delete problematic resources:
```bash
gcloud iam service-accounts delete SA_EMAIL --project=PROJECT_ID
```

4. Re-apply from clean state

## Support and Resources

### Documentation
- [Architecture Overview](ARCHITECTURE.md)
- [Component Reference](COMPONENTS.md)
- [Workload Identity Guide](WORKLOAD_IDENTITY.md)

### External Resources
- [Terraform Stacks Documentation](https://developer.hashicorp.com/terraform/language/stacks)
- [Google Cloud Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GCP IAM Best Practices](https://cloud.google.com/iam/docs/best-practices)

### Getting Support

For issues:
1. Check this troubleshooting guide
2. Review component-specific documentation
3. Check GCP status page
4. Contact infrastructure team

