# infra-gcp

IAC repo for external GCP infrastructure management, focused on Kubernetes service accounts, Workload Identity
Federation, and secret management.

## Contents

### Getting Started

- [Deployment Guide](DEPLOYMENT.md) - Step-by-step deployment instructions, troubleshooting, and operations
- [Architecture Overview](ARCHITECTURE.md) - System architecture, data flows, and design patterns

### Technical Reference

- [Component Reference](COMPONENTS.md) - Detailed documentation for each Terraform component
- [Workload Identity Federation](WORKLOAD_IDENTITY.md) - WIF setup, testing, and troubleshooting

## Quick Links

### For Operators

- [Prerequisites](DEPLOYMENT.md#prerequisites)
- [Authentication Setup](DEPLOYMENT.md#authentication-setup)
- [Deployment Workflow](DEPLOYMENT.md#step-by-step-deployment)
- [Troubleshooting](DEPLOYMENT.md#troubleshooting)

### For Developers

- [Architecture Diagrams](ARCHITECTURE.md#stack-structure)
- [Component Documentation](COMPONENTS.md)
- [Data Flow](ARCHITECTURE.md#data-flow)
- [Best Practices](ARCHITECTURE.md#best-practices)

## Stack Overview

This Terraform Stack manages the following GCP services:

### Service Account Management

- GCP service account creation
- IAM role assignment
- Service account lifecycle management
- Multi-purpose service accounts for different workloads

### Secret Management

- Secret Manager integration
- Pub/Sub topic creation for secret rotation notifications
- CA certificate rotation notification system
- Kubernetes secret integration

### Workload Identity Federation

- Kubernetes workload authentication to GCP
- OIDC-based identity federation
- Service account impersonation
- Zero Trust security model

### Kubernetes Integration

- Kubernetes service account creation
- Service account annotation management
- Workload Identity binding
- Multi-cluster support

## Architecture Highlights

### Zero Trust Security

All Kubernetes workloads authenticate to GCP using Workload Identity Federation, eliminating the need for static
credentials.

### Component-Based Design

Each infrastructure concern is isolated into its own component with clear inputs and outputs.

### Multi-Cluster Support

The stack supports multiple Kubernetes clusters with environment-specific configurations.

### Infrastructure as Code

Complete infrastructure defined in HCL with version control and peer review.

## Quick Start

1. Install prerequisites (Terraform 1.9.0+, GCP account, kubectl)
2. Configure authentication (Workload Identity Federation for Terraform Cloud)
3. Set up Kubernetes cluster credentials
4. Run `terraform init`
5. Run `terraform plan`
6. Run `terraform apply`
7. Test Workload Identity from Kubernetes pods
8. Verify service account permissions

See [Deployment Guide](DEPLOYMENT.md) for detailed instructions.

## Component Dependencies

```
providers → components → deployments
    ↓           ↓            ↓
variables → service-account → workload-identity → kubernetes-sa
              ↓
          secret-manager
```

Workload Identity Federation depends on Service Accounts being created first.

## Key Features

- Declarative infrastructure management
- Workload Identity Federation for secure authentication
- Automated service account provisioning
- Secret Manager integration with rotation notifications
- Kubernetes service account automation
- Multi-cluster support
- IAM role management
- Comprehensive monitoring and logging

## Managed Resources

### GCP Service Accounts

- `k8s-admin` - Kubernetes cluster administration
- `k8s-secret-reader` - Secret Manager access for applications
- `k8s-storage-admin` - Cloud Storage management
- `k8s-monitoring` - Monitoring and logging

### Kubernetes Service Accounts

- `cluster-admin` (kube-system) - Cluster administration tasks
- `default-app` (default) - Application workloads with secret access

### Pub/Sub Topics

- `k8s-ca-rotation-*` - Certificate rotation notifications per cluster

## References

- [Terraform Stacks Documentation](https://developer.hashicorp.com/terraform/language/stacks)
- [Google Cloud Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Workload Identity Federation Documentation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)
- [GKE Workload Identity Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
