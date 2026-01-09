# External Clusters Configuration

This directory contains Kubernetes Secrets that register external EKS clusters with Argo CD, enabling Argo CD to deploy applications to remote clusters.

Based on the [Argo CD Declarative Setup documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#eks), this guide covers connecting to EKS clusters using `awsAuthConfig` with `roleARN`.

> **Important**: Use the **Kubernetes API server URL** in the `server` field with `awsAuthConfig` and `roleARN` in the `config` field.

## Cluster Type Labels

Clusters are separated into two types using the `cluster.type` label:

- **`cluster.type: platform`** - Platform/DevOps clusters
  - Host Argo CD control plane
  - Run infrastructure components (monitoring, logging, secrets management)
  - Managed by `infrastructure` ApplicationSet

- **`cluster.type: application`** - Application clusters
  - Run business applications
  - Separated by environment (`kubernetes.io/environment`)
  - Managed by `apps-dev` and `apps-prod` ApplicationSets
  - Bootstrap components deploy here (when labeled with `cluster.bootstrap.*: "true"`)

This separation ensures infrastructure components deploy only to platform clusters, while applications and bootstrap components deploy to dedicated application clusters.

## Table of Contents

- [Cluster Type Labels](#cluster-type-labels)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Setup Steps](#setup-steps)
- [Complete Example Flow](#complete-example-flow)
- [Cross-Account and Cross-Region Clusters](#cross-account-and-cross-region-clusters)
- [Private Clusters](#private-clusters)
- [Verification](#verification)
- [Usage with ApplicationSets](#usage-with-applicationsets)
- [Resources](#resources)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│   Argo CD Cluster (Management Cluster)                                      │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │  Argo CD Components                                                  │  │
│   │  ┌──────────────────┐   ┌──────────────────┐   ┌────────────────┐    │  │
│   │  │ application-     │   │ applicationset-  │   │ argocd-server  │    │  │
│   │  │ controller       │   │ controller       │   │                │    │  │
│   │  └────────┬─────────┘   └────────┬─────────┘   └────────┬───────┘    │  │
│   │           │                      │                      │            │  │
│   │           └──────────────────────┼──────────────────────┘            │  │
│   │                                  │                                   │  │
│   │   ┌──────────────────────────────▼──────────────────────────────┐    │  │
│   │   │  Service Accounts (IRSA)                                    │    │  │
│   │   │  eks.amazonaws.com/role-arn: ArgoCDManagementRole           │    │  │
│   │   └──────────────────────────────┬──────────────────────────────┘    │  │
│   └──────────────────────────────────┼───────────────────────────────────┘  │
│                                      │                                      │
│  ┌───────────────────────────────────▼───────────────────────────────────┐  │
│  │  Argo CD Management Role                                              │  │
│  │  - Assumes cluster roles for each managed cluster                     │  │
│  └───────────────────────────────────┬───────────────────────────────────┘  │
└──────────────────────────────────────┼──────────────────────────────────────┘
                                       │
                                       │ AssumeRole
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────┐
│  Remote Cluster (Target Cluster)                                            │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  EKS Access Entry                                                   │   │
│   │  - Grants RBAC permissions to Management Role                       │   │
│   │  - Same Management Role used for all clusters                       │   │
│   └────────────────────────────┬────────────────────────────────────────┘   │
│                                │                                            │
│                                │                                            │
│  ┌─────────────────────────────▼───────────────────────────┐                │
│  │  EKS Cluster API                                        │                │
│  │  - Receives deployments                                 │                │
│  │  - Runs workloads                                       │                │
│  └─────────────────────────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### On Argo CD Cluster
- Argo CD installed and running
- IRSA (IAM Roles for Service Accounts) enabled on the Argo CD EKS cluster
- IAM OIDC provider configured for the Argo CD cluster
- `kubectl` configured to access Argo CD cluster

### On Remote Cluster (Destination)
- EKS cluster created and accessible
- IAM role for the cluster configured with trust policy allowing Argo CD Management Role to assume it
- EKS access entries configured for the Management Role
- `kubectl` configured to access remote cluster (for verification)

## Setup Steps

This guide follows the **Argo CD Management Role** pattern, which is the recommended approach for managing multiple EKS clusters. This pattern uses a single management role that assumes cluster-specific roles, providing better scalability and security.

### Step 1: Create Argo CD Management Role

**Where**: AWS IAM (in the Argo CD cluster's account)

**What happens**: Create a single IAM role that Argo CD will use to assume roles for each managed cluster.

The Argo CD Management Role needs:
1. **Trust Policy** allowing assumption by Argo CD service accounts and itself
2. **Permission Policy** allowing it to assume roles for each managed cluster

**Create the Management Role**:

```bash
# Create the IAM role (replace placeholders)
aws iam create-role \
  --role-name ArgoCDManagementRole \
  --assume-role-policy-document file://trust-policy.json
```

**Trust Policy** (`trust-policy.json`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ExplicitSelfRoleAssumption",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "ArnLike": {
          "aws:PrincipalArn": "arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole"
        }
      }
    },
    {
      "Sid": "ServiceAccountRoleAssumption",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:oidc-provider/oidc.eks.<ARGO_CD_AWS_REGION>.amazonaws.com/id/<OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<ARGO_CD_AWS_REGION>.amazonaws.com/id/<OIDC_ID>:sub": [
            "system:serviceaccount:argocd:argocd-application-controller",
            "system:serviceaccount:argocd:argocd-applicationset-controller",
            "system:serviceaccount:argocd:argocd-server"
          ],
          "oidc.eks.<ARGO_CD_AWS_REGION>.amazonaws.com/id/<OIDC_ID>:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

**Permission Policy** (attach to the management role):

The Management Role doesn't need permission policies when used directly. RBAC permissions are granted via EKS Access Entries on each cluster.

### Step 2: Configure Argo CD Service Accounts

**Where**: **Argo CD Cluster** (where Argo CD is running)

**What happens**: Annotate Argo CD service accounts with the management role ARN to enable IRSA.

**Update Service Accounts**:

The service account annotations are configured in the ArgoCD Helm values file. Update `_bootstraps/argocd.yml` to include the Management Role ARN annotations:

```yaml
controller:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole"

server:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole"

applicationSet:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole"
```

**Important**: After updating the values file and deploying ArgoCD, restart the pods to ensure the service accounts pick up the annotations:

```bash

helm upgrade --install argo-cd argo/argo-cd \
                --version 8.2.5 \
                --namespace argocd \
                --values _bootstraps/argocd.yml

kubectl rollout restart deployment argocd-application-controller -n argocd
kubectl rollout restart deployment argocd-applicationset-controller -n argocd
kubectl rollout restart deployment argocd-server -n argocd
```

### Step 3: Configure EKS Cluster Access

**Where**: **Remote Cluster** (the EKS cluster where applications will be deployed)

**What happens**: Grant the Argo CD Management Role access to the remote EKS cluster so Argo CD can authenticate.

**On Remote Cluster** (or from a machine with access to the remote cluster's AWS account):
```bash
aws eks create-access-entry \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole \
  --type STANDARD \
  --kubernetes-groups [] \
  --region <region>

aws eks associate-access-policy \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region <region>
```

**Note**: Repeat this step for each cluster you want to manage.

### Step 4: Register Cluster Secret on Argo CD Cluster

**Where**: **Argo CD Cluster** (where Argo CD is running)

**What happens**: Create a Kubernetes Secret that registers the remote cluster with Argo CD. This secret tells Argo CD how to connect to the remote cluster.

Create a Kubernetes Secret with `awsAuthConfig` and `roleARN` for IAM role assumption:

**Example: `eks-cluster-secret.yaml`**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mycluster-secret  # TODO: Update with your cluster name
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    cluster.type: platform  # Required: "platform" for DevOps/Management clusters, "application" for app clusters
    kubernetes.io/environment: production  # Optional: for ApplicationSet selectors (development, staging, production)
type: Opaque
stringData:
  name: eks-cluster-name-for-argo  # TODO: Update with your cluster name
  # Kubernetes API server URL (NOT cluster ARN)
  # Format: https://<cluster-id>.gr7.<region>.eks.amazonaws.com
  server: https://xxxyyyzzz.xyz.some-region.eks.amazonaws.com  # TODO: Update with your EKS endpoint
  config: |
    {
      "awsAuthConfig": {
        "clusterName": "my-eks-cluster-name",  # TODO: Update with your EKS cluster name
        "roleARN": "arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole"  # Use Management Role for all clusters
      },
      "tlsClientConfig": {
        "insecure": false,
        "caData": "<base64 encoded certificate>"  # Optional: Base64-encoded CA certificate
      }
    }
```

**Customization Required**:
1. Update `metadata.name` with your cluster name
2. Update `stringData.name` with your cluster name
3. Update `stringData.server` with your EKS cluster endpoint URL
4. Update `awsAuthConfig.clusterName` with your EKS cluster name
5. Update `awsAuthConfig.roleARN` with the Argo CD Management Role ARN (same for all clusters)
6. Optionally add `caData` if using a custom CA certificate

**How it works**:
1. You commit this secret file to Git (in `argocd/external-clusters/`)
2. The `root-external-clusters` Application syncs this directory to the **Argo CD Cluster**
3. Argo CD discovers the secret via the `argocd.argoproj.io/secret-type: cluster` label
4. Argo CD service accounts (using the Management Role via IRSA) use the Management Role specified in `roleARN`
5. The Management Role authenticates to the **Remote Cluster** (EKS cluster)
6. The Management Role's permissions (via Access Entries on each cluster) determine what Argo CD can do in the cluster

**Verify on Argo CD Cluster**:
```bash
# Check secret exists
kubectl get secret mycluster-secret -n argocd

# Verify secret contents
kubectl get secret mycluster-secret -n argocd -o yaml

# Check Argo CD recognizes the cluster
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=cluster
```

**Verify in Argo CD UI**:
1. Navigate to **Settings → Clusters**
2. You should see the remote cluster listed
3. Status should show as "Connected" (green)

## Complete Example Flow

This section provides a complete end-to-end example for registering a production EKS cluster.

### Example: Production Cluster Setup

**Scenario**: Register a production EKS cluster named `production-cluster` in account `111122223333`. Argo CD Management Role is `arn:aws:iam::999988887777:role/ArgoCDManagementRole`.

**Step 1**: Configure EKS cluster access (on remote cluster):

```bash
aws eks create-access-entry \
  --cluster-name production-cluster \
  --principal-arn arn:aws:iam::999988887777:role/ArgoCDManagementRole \
  --type STANDARD \
  --kubernetes-groups [] \
  --region us-west-2

aws eks associate-access-policy \
  --cluster-name production-cluster \
  --principal-arn arn:aws:iam::999988887777:role/ArgoCDManagementRole \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-west-2
```

**Step 2**: Create cluster secret file (on Argo CD cluster via Git):

```bash
cat > argocd/external-clusters/production-cluster.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: production-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    cluster.type: application
    kubernetes.io/environment: production
type: Opaque
stringData:
  name: production-cluster
  server: https://abc123def456.gr7.us-west-2.eks.amazonaws.com
  config: |
    {
      "awsAuthConfig": {
        "clusterName": "production-cluster",
        "roleARN": "arn:aws:iam::999988887777:role/ArgoCDManagementRole"
      },
      "tlsClientConfig": {
        "insecure": false
      }
    }
EOF

git add argocd/external-clusters/production-cluster.yaml
git commit -m "Add production cluster"
git push
```

**Step 3**: Verify:

```bash
# Check secret exists
kubectl get secret production-cluster -n argocd

# Verify in Argo CD UI: Settings → Clusters
```

## Verification

### On Argo CD Cluster

```bash
# List all registered clusters
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=cluster

# Check specific cluster secret
kubectl get secret <cluster-name> -n argocd -o yaml

# Verify config format
kubectl get secret <cluster-name> -n argocd -o jsonpath='{.data.config}' | base64 -d | jq

# Verify server URL
kubectl get secret <cluster-name> -n argocd -o jsonpath='{.data.server}' | base64 -d

# Check in Argo CD UI: Settings → Clusters
```

### On Remote Cluster

```bash
# Verify access entry exists
aws eks describe-access-entry \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole \
  --region <region>

# Verify access policy is associated
aws eks list-associated-access-policies \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ARGO_CD_AWS_ACCOUNT_ID>:role/ArgoCDManagementRole \
  --region <region>
```

## Architecture: Management Role Pattern

The Argo CD Management Role pattern provides several advantages:

- **Centralized Management**: Single role used for all clusters
- **Simplicity**: No need to create cluster-specific roles
- **Scalability**: Easy to add new clusters - just configure EKS access and create cluster secret
- **Security**: Access is granted via EKS Access Entries on each cluster
- **Best Practice**: Follows AWS and Argo CD recommended patterns

**Flow**:
1. Argo CD service accounts (annotated with Management Role ARN) use IRSA to use the Management Role
2. Management Role authenticates directly to each EKS cluster API using `argocd-k8s-auth`
3. EKS Access Entries grant RBAC permissions to the Management Role on each cluster
4. The same Management Role ARN is used in all cluster secrets

## Resources

- [Argo CD Declarative Setup - EKS](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#eks)
- [Argo CD Management Role](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#argo-cd-management-role)
- [EKS Access Entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
