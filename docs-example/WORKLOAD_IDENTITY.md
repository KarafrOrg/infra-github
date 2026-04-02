# Workload Identity Federation Guide

This guide provides comprehensive information about Workload Identity Federation (WIF) setup, testing, and troubleshooting for Kubernetes workloads authenticating to GCP.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [How It Works](#how-it-works)
- [Setup Instructions](#setup-instructions)
- [Testing Workload Identity](#testing-workload-identity)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Overview

Workload Identity Federation allows Kubernetes workloads to authenticate to GCP services without using static service account keys. This provides:

- **Enhanced Security**: No long-lived credentials to manage or rotate
- **Zero Trust Architecture**: Identity-based authentication with short-lived tokens
- **Simplified Operations**: Automatic token acquisition and renewal
- **Fine-Grained Access**: Per-workload GCP service account mapping

### Architecture

```
Kubernetes Pod → K8s Service Account → GKE Metadata Server → 
STS Token Exchange → GCP Service Account → GCP APIs
```

## Prerequisites

### GCP Requirements

1. **GKE Cluster with Workload Identity Enabled** (for GKE):
   ```bash
   gcloud container clusters describe CLUSTER_NAME \
     --zone=ZONE \
     --project=PROJECT_ID \
     --format="value(workloadIdentityConfig.workloadPool)"
   ```
   Should return: `PROJECT_ID.svc.id.goog`

2. **Required APIs Enabled**:
   - IAM Service Account Credentials API
   - Security Token Service (STS) API
   - Kubernetes Engine API (for GKE)

   ```bash
   gcloud services enable \
     iamcredentials.googleapis.com \
     sts.googleapis.com \
     container.googleapis.com \
     --project=PROJECT_ID
   ```

3. **GCP Service Account**: Created with appropriate IAM roles

### Kubernetes Requirements

1. **Kubernetes Service Account**: Created with proper annotation
2. **Workload Identity Node Pool** (for GKE): Node pool must have Workload Identity enabled
3. **OIDC Configuration** (for non-GKE): Cluster must expose OIDC discovery endpoint

### Information Needed

- **Project ID**: Your GCP project ID
- **Project Number**: GCP project number
- **Cluster Name**: Kubernetes cluster identifier
- **JWKS Data**: JSON Web Key Set for token validation
- **Issuer URI**: OIDC issuer URI of your cluster

## How It Works

### Authentication Flow

1. **Pod Requests Access**: Application code requests GCP credentials
2. **Token Request**: Kubernetes service account token is obtained
3. **Metadata Server**: GKE metadata server intercepts the request
4. **Token Exchange**: K8s token is exchanged for GCP token via STS
5. **Validation**: Google validates the token using JWKS
6. **Impersonation**: Caller impersonates configured GCP service account
7. **API Access**: Application accesses GCP APIs with temporary credentials

### Components

```
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes Pod                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Application Code                                        │ │
│ │ - Uses Google Cloud SDK                                 │ │
│ │ - Requests default credentials                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│          ↓                                                  │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Kubernetes Service Account                              │ │
│ │ - Annotation: iam.gke.io/gcp-service-account            │ │
│ │ - Mounted token at /var/run/secrets/kubernetes.io/...   │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
          ↓
┌─────────────────────────────────────────────────────────────┐
│ GKE Metadata Server (169.254.169.254)                       │
│ - Intercepts credential requests                            │
│ - Exchanges K8s token for GCP token                         │
└─────────────────────────────────────────────────────────────┘
          ↓
┌─────────────────────────────────────────────────────────────┐
│ Google STS (Security Token Service)                         │
│ - Validates Kubernetes token using JWKS                     │
│ - Issues federated token                                    │
└─────────────────────────────────────────────────────────────┘
          ↓
┌─────────────────────────────────────────────────────────────┐
│ GCP Service Account                                         │
│ - Has workloadIdentityUser role binding                     │
│ - Grants access to GCP resources                            │
└─────────────────────────────────────────────────────────────┘
```

## Setup Instructions

### For GKE Clusters

#### 1. Enable Workload Identity on Cluster

If not already enabled:

```bash
gcloud container clusters update CLUSTER_NAME \
  --zone=ZONE \
  --project=PROJECT_ID \
  --workload-pool=PROJECT_ID.svc.id.goog
```

#### 2. Enable Workload Identity on Node Pool

```bash
gcloud container node-pools update NODE_POOL_NAME \
  --cluster=CLUSTER_NAME \
  --zone=ZONE \
  --project=PROJECT_ID \
  --workload-metadata=GKE_METADATA
```

#### 3. Verify Configuration

The Terraform stack handles:
- Creating GCP service accounts
- Creating IAM bindings for workload identity user
- Creating Kubernetes service accounts with annotations
- Mapping K8s service accounts to GCP service accounts

### For Non-GKE Clusters

#### 1. Obtain JWKS Data

Extract JWKS from your cluster:

```bash
# Get service account token
SA_TOKEN=$(kubectl create token default -n kube-system --duration=1h)

# Decode token to get issuer
echo $SA_TOKEN | cut -d'.' -f2 | base64 -d | jq -r '.iss'

# Fetch JWKS
ISSUER="<issuer-from-above>"
curl ${ISSUER}/.well-known/openid-configuration | jq -r '.jwks_uri' | xargs curl
```

#### 2. Configure Workload Identity Pool

The Terraform stack creates the workload identity pool and provider using the JWKS data.

#### 3. Store JWKS in Terraform Cloud

Add JWKS data to the variable set:
- Variable name: `stable.jwks_json_data` (or per-cluster variable)
- Value: JWKS JSON data
- Mark as sensitive

## Testing Workload Identity

### Quick Verification

#### 1. Check Prerequisites

```bash
# Verify GKE Workload Identity is enabled
gcloud container clusters describe CLUSTER_NAME \
  --zone=ZONE \
  --project=PROJECT_ID \
  --format="value(workloadIdentityConfig.workloadPool)"

# Should return: PROJECT_ID.svc.id.goog
```

#### 2. Verify Service Account Configuration

```bash
# Check Kubernetes service account annotation
kubectl get sa cluster-admin -n kube-system -o yaml | grep -A 2 annotations

# Should show:
# annotations:
#   iam.gke.io/gcp-service-account: k8s-admin@PROJECT_ID.iam.gserviceaccount.com
```

#### 3. Verify IAM Binding

```bash
# Check workload identity user binding
gcloud iam service-accounts get-iam-policy \
  k8s-admin@PROJECT_ID.iam.gserviceaccount.com \
  --project=PROJECT_ID \
  --format=json | jq '.bindings[] | select(.role=="roles/iam.workloadIdentityUser")'

# Should show:
# {
#   "members": [
#     "serviceAccount:PROJECT_ID.svc.id.goog[kube-system/cluster-admin]"
#   ],
#   "role": "roles/iam.workloadIdentityUser"
# }
```

### Comprehensive Testing

#### 1. Deploy Test Pod with Admin Permissions

```bash
# Create test pod using cluster-admin service account
kubectl run wif-test-admin \
  --image=google/cloud-sdk:slim \
  --namespace=kube-system \
  --overrides='{"spec":{"serviceAccountName":"cluster-admin"}}' \
  --command -- sleep infinity

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/wif-test-admin -n kube-system --timeout=60s
```

#### 2. Test Authentication

```bash
# Check if authentication works
kubectl exec -it wif-test-admin -n kube-system -- bash -c '
  echo "=== Testing Workload Identity ==="
  echo "Current identity:"
  gcloud auth list
  
  echo -e "\n=== Metadata Server Response ==="
  curl -H "Metadata-Flavor: Google" \
    http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
  
  echo -e "\n=== Testing GCP API Access ==="
  gcloud projects describe PROJECT_ID --format="value(projectId,name)"
'
```

**Expected Output**:
```
=== Testing Workload Identity ===
Current identity:
                   Credentialed Accounts
ACTIVE  ACCOUNT
*       k8s-admin@PROJECT_ID.iam.gserviceaccount.com

=== Metadata Server Response ===
k8s-admin@PROJECT_ID.iam.gserviceaccount.com

=== Testing GCP API Access ===
PROJECT_ID      Project Name
```

#### 3. Test Service-Specific Permissions

```bash
# Test GKE admin access (if service account has container.admin)
kubectl exec -it wif-test-admin -n kube-system -- \
  gcloud container clusters list --project=PROJECT_ID

# Test IAM permissions
kubectl exec -it wif-test-admin -n kube-system -- \
  gcloud iam service-accounts list --project=PROJECT_ID
```

#### 4. Test Application Service Account

```bash
# Deploy test pod using default-app service account
kubectl run wif-test-app \
  --image=google/cloud-sdk:slim \
  --namespace=default \
  --overrides='{"spec":{"serviceAccountName":"default-app"}}' \
  --command -- sleep infinity

# Test Secret Manager access
kubectl exec -it wif-test-app -n default -- bash -c '
  echo "=== Testing Secret Manager Access ==="
  gcloud auth list
  
  echo -e "\n=== Listing Secrets ==="
  gcloud secrets list --project=PROJECT_ID
  
  echo -e "\n=== Testing Pub/Sub Topic Access ==="
  gcloud pubsub topics describe k8s-ca-rotation-k8s-production --project=PROJECT_ID
'
```

#### 5. Clean Up Test Pods

```bash
kubectl delete pod wif-test-admin -n kube-system
kubectl delete pod wif-test-app -n default
```

### Automated Testing Script

Create a test script `test-wif.sh`:

```bash
#!/bin/bash
set -e

PROJECT_ID="${1:-karafra-net}"
NAMESPACE="${2:-kube-system}"
SA_NAME="${3:-cluster-admin}"

echo "Testing Workload Identity for $SA_NAME in $NAMESPACE"

# Deploy test pod
kubectl run wif-test-${SA_NAME} \
  --image=google/cloud-sdk:slim \
  --namespace=${NAMESPACE} \
  --overrides="{\"spec\":{\"serviceAccountName\":\"${SA_NAME}\"}}" \
  --command -- sleep infinity

# Wait for ready
kubectl wait --for=condition=ready pod/wif-test-${SA_NAME} -n ${NAMESPACE} --timeout=60s

# Run tests
kubectl exec -it wif-test-${SA_NAME} -n ${NAMESPACE} -- bash -c "
  set -e
  echo 'Pod is running with service account: ${SA_NAME}'
  
  echo 'Testing authentication...'
  if gcloud auth list | grep -q '@'; then
    echo 'Successfully authenticated to GCP'
    gcloud auth list
  else
    echo 'Authentication failed'
    exit 1
  fi
  
  echo 'Testing project access...'
  if gcloud projects describe ${PROJECT_ID} &>/dev/null; then
    echo 'Can access project ${PROJECT_ID}'
  else
    echo 'Cannot access project'
    exit 1
  fi
  
  echo 'All tests passed!'
"

# Cleanup
kubectl delete pod wif-test-${SA_NAME} -n ${NAMESPACE}
echo "Test completed and cleaned up"
```

Usage:
```bash
chmod +x test-wif.sh
./test-wif.sh karafra-net kube-system cluster-admin
./test-wif.sh karafra-net default default-app
```

## Troubleshooting

### Issue: "No credentialed accounts" in Pod

**Symptoms**:
```
No credentialed accounts.
To login, run: gcloud auth login
```

**Diagnosis Steps**:

1. Check service account annotation:
```bash
kubectl get sa SERVICE_ACCOUNT_NAME -n NAMESPACE -o yaml
```

2. Verify annotation exists:
```yaml
metadata:
  annotations:
    iam.gke.io/gcp-service-account: GCP_SA_EMAIL
```

3. Check IAM binding:
```bash
gcloud iam service-accounts get-iam-policy GCP_SA_EMAIL --project=PROJECT_ID
```

**Solutions**:

- **Missing Annotation**: Re-apply Terraform configuration
- **Missing IAM Binding**: Check Terraform state and re-apply
- **Wrong Service Account Email**: Update configuration and re-apply

### Issue: "Error 403: Permission denied"

**Symptoms**:
```
ERROR: (gcloud.container.clusters.list) You do not currently have this permission
```

**Diagnosis**:

1. Verify which identity is active:
```bash
kubectl exec POD_NAME -- gcloud auth list
```

2. Check GCP service account roles:
```bash
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:GCP_SA_EMAIL"
```

**Solutions**:

- **Missing Role**: Add required role in `deployments.tfdeploy.hcl` and apply
- **Wrong Service Account**: Verify annotation points to correct GCP SA
- **IAM Propagation Delay**: Wait 60-120 seconds after IAM changes

### Issue: "Invalid JWT" or Token Validation Errors

**Symptoms**:
```
Error: invalid_grant: Invalid JWT Signature
```

**Diagnosis**:

1. Check issuer URI configuration:
```bash
# From Terraform configuration
grep issuer_uri deployments.tfdeploy.hcl
```

2. Verify JWKS is correct:
```bash
# Get actual issuer from token
kubectl run test --rm -i --tty --image=google/cloud-sdk:slim -- bash
kubectl create token default | cut -d'.' -f2 | base64 -d | jq -r '.iss'
```

3. Verify JWKS matches cluster:
```bash
# Compare configured JWKS with cluster JWKS
curl ${ISSUER}/.well-known/openid-configuration | jq -r '.jwks_uri' | xargs curl
```

**Solutions**:

- **Wrong Issuer**: Update `issuer_uri` in configuration
- **Stale JWKS**: Rotate JWKS and update in Terraform Cloud variables
- **Audience Mismatch**: Verify `allowed_audiences` includes `sts.googleapis.com`

### Issue: Workload Identity Not Enabled on Cluster

**Symptoms**:
```
Workload Identity is not enabled on this cluster
```

**Solution**:

Enable Workload Identity:
```bash
gcloud container clusters update CLUSTER_NAME \
  --zone=ZONE \
  --project=PROJECT_ID \
  --workload-pool=PROJECT_ID.svc.id.goog

# Update node pool
gcloud container node-pools update NODE_POOL_NAME \
  --cluster=CLUSTER_NAME \
  --zone=ZONE \
  --workload-metadata=GKE_METADATA
```

### Issue: Metadata Server Not Responding

**Symptoms**:
```
curl: (7) Failed to connect to 169.254.169.254
```

**Diagnosis**:

1. Check node pool configuration:
```bash
gcloud container node-pools describe NODE_POOL_NAME \
  --cluster=CLUSTER_NAME \
  --zone=ZONE \
  --format="value(config.workloadMetadataConfig.mode)"
```

Should return: `GKE_METADATA`

**Solutions**:

- **Wrong Metadata Mode**: Update node pool workload metadata
- **Network Policy**: Check for network policies blocking metadata server
- **CNI Issues**: Verify cluster networking is healthy

### Debug Commands

```bash
# Check pod's service account
kubectl get pod POD_NAME -n NAMESPACE -o jsonpath='{.spec.serviceAccountName}'

# Check mounted service account token
kubectl exec POD_NAME -n NAMESPACE -- cat /var/run/secrets/kubernetes.io/serviceaccount/token | cut -d'.' -f2 | base64 -d | jq

# Test metadata server manually
kubectl exec POD_NAME -n NAMESPACE -- curl -H "Metadata-Flavor: Google" \
  http://169.254.169.254/computeMetadata/v1/instance/service-accounts/

# Check environment variables
kubectl exec POD_NAME -n NAMESPACE -- env | grep GOOGLE

# Verbose gcloud auth
kubectl exec POD_NAME -n NAMESPACE -- gcloud auth list --verbosity=debug
```

## Best Practices

### Security

1. **Principle of Least Privilege**: Grant minimum required GCP permissions
2. **Separate Service Accounts**: Use different service accounts per workload type
3. **Namespace Isolation**: Isolate sensitive workloads in separate namespaces
4. **Regular Audits**: Review service account usage and permissions quarterly
5. **No Service Account Keys**: Never create or use service account keys

### Configuration

1. **Descriptive Names**: Use clear naming for both K8s and GCP service accounts
2. **Labels**: Add labels to identify purpose and ownership
3. **Documentation**: Document the purpose of each service account mapping
4. **Version Control**: Store all configuration in Git
5. **Peer Review**: Require reviews for IAM changes

### Operations

1. **Test First**: Test WIF in development before production
2. **Monitor Authentication**: Set up alerts for authentication failures
3. **JWKS Rotation**: Plan for periodic JWKS rotation
4. **Token Caching**: Rely on GKE's built-in token caching
5. **Graceful Degradation**: Handle authentication failures gracefully in applications

### Application Development

1. **Use Official SDKs**: Use Google Cloud client libraries
2. **Application Default Credentials**: Use ADC (Application Default Credentials)
3. **Error Handling**: Handle credential errors properly
4. **Retry Logic**: Implement retries for transient failures
5. **Logging**: Log authentication attempts (not tokens!)

### Example Application Code

#### Python
```python
from google.cloud import secretmanager

# Uses Application Default Credentials automatically
client = secretmanager.SecretManagerServiceClient()
name = f"projects/PROJECT_ID/secrets/SECRET_NAME/versions/latest"
response = client.access_secret_version(request={"name": name})
```

#### Go
```go
import (
    "context"
    secretmanager "cloud.google.com/go/secretmanager/apiv1"
)

// Uses Application Default Credentials automatically
ctx := context.Background()
client, err := secretmanager.NewClient(ctx)
```

#### Node.js
```javascript
const {SecretManagerServiceClient} = require('@google-cloud/secret-manager');

// Uses Application Default Credentials automatically
const client = new SecretManagerServiceClient();
```

## Performance Considerations

### Token Caching

- GKE metadata server caches tokens automatically
- Token TTL is typically 1 hour
- No action needed from applications

### Rate Limits

- STS has rate limits per project
- Design for token reuse across requests
- Avoid requesting new tokens for each API call

### Latency

- First token acquisition: 100-500ms
- Cached token: <10ms
- Token refresh: Automatic and transparent

## References

- [GKE Workload Identity Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Configuring Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Best Practices for Workload Identity](https://cloud.google.com/kubernetes-engine/docs/best-practices/workload-identity)
- [Troubleshooting Workload Identity](https://cloud.google.com/kubernetes-engine/docs/troubleshooting/workload-identity)
