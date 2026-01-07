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
┌─────────────────────────────────┐         ┌────────────────────────────────┐
│   Argo CD Cluster               │         │   Remote Cluster (Target)      │
│   (Where Argo CD runs)          │         │   (Where apps will deploy)     │
│                                 │         │                                │
│  ┌──────────────────────────┐   │         │  ┌──────────────────────────┐  │
│  │  Argo CD Server          │   │         │  │  EKS Cluster             │  │
│  │  - Manages applications  │   │◄───────►│  │ - Receives deployments   │  │
│  │  - Monitors sync status  │   │         │  │ - Runs workloads         │  │
│  └──────────────────────────┘   │         │  └──────────────────────────┘  │
│                                 │         │                                │
│  ┌──────────────────────────┐   │         │  ┌──────────────────────────┐  │
│  │  Cluster Secret          │   │         │  │  IAM Role                │  │
│  │  (This directory)        │   │         │  │  - Assumed by Argo CD    │  │
│  └──────────────────────────┘   │         │  └──────────────────────────┘  │
│                                 │         │                                │
│  ┌──────────────────────────┐   │         │  ┌──────────────────────────┐  │
│  │  awsAuthConfig           │   │         │  │  aws-auth ConfigMap      │  │
│  │  - roleARN               │   │         │  │  - Maps role to RBAC     │  │
│  └──────────────────────────┘   │         │  └──────────────────────────┘  │
└─────────────────────────────────┘         └────────────────────────────────┘
```

## Prerequisites

### On Argo CD Cluster
- Argo CD installed and running
- `kubectl` configured to access Argo CD cluster
- IAM role with permissions to access EKS cluster

### On Remote Cluster (Destination)
- EKS cluster created and accessible
- IAM role configured with trust policy allowing Argo CD to assume it
- IAM role/user added to the cluster's aws-auth ConfigMap or EKS access entries configured
- `kubectl` configured to access remote cluster (for verification)

## Setup Steps

### Step 1: Configure IAM Role

**Where**: AWS IAM (not cluster-specific, but role should be in the remote cluster's account)

**What happens**: Create or configure an IAM role that Argo CD will assume to access the remote EKS cluster.

Ensure you have an IAM role that:
- Has permissions to assume the role (if using cross-account)
- Has trust policy allowing Argo CD's service account/role to assume it
- Has necessary EKS permissions (or is added to the cluster's aws-auth ConfigMap)

**Example IAM Trust Policy** (if Argo CD runs on EKS with IRSA):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.<REGION>.amazonaws.com/id/<OIDC_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<REGION>.amazonaws.com/id/<OIDC_ID>:sub": "system:serviceaccount:argocd:argocd-repo-server",
          "oidc.eks.<REGION>.amazonaws.com/id/<OIDC_ID>:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

### Step 2: Configure EKS Cluster Access

**Where**: **Remote Cluster** (the EKS cluster where applications will be deployed)

**What happens**: Grant the IAM role access to the remote EKS cluster so Argo CD can authenticate using the assumed role.

Add the IAM role to the EKS cluster's aws-auth ConfigMap or configure EKS access entries:

**Option A: Using aws-auth ConfigMap** (Traditional method):

**On Remote Cluster**:
```bash
# Get the aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Add the IAM role to the mapRoles section
kubectl edit configmap aws-auth -n kube-system
```

Add to `mapRoles`:
```yaml
mapRoles: |
  - rolearn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>
    username: system:node:{{EC2PrivateDNSName}}
    groups:
      - system:masters
```

**Option B: Using EKS Access Entries** (Modern method):

**On Remote Cluster** (or from a machine with access to the remote cluster's AWS account):
```bash
aws eks create-access-entry \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME> \
  --type STANDARD \
  --region <region>

aws eks associate-access-policy \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME> \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region <region>
```

### Step 3: Register Cluster Secret on Argo CD Cluster

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
        "roleARN": "arn:aws:iam::<AWS_ACCOUNT_ID>:role/<IAM_ROLE_NAME>"  # TODO: Update with your IAM role ARN
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
5. Update `awsAuthConfig.roleARN` with your IAM role ARN
6. Optionally add `caData` if using a custom CA certificate

**How it works**:
1. You commit this secret file to Git (in `argocd/external-clusters/`)
2. The `root-external-clusters` Application syncs this directory to the **Argo CD Cluster**
3. Argo CD discovers the secret via the `argocd.argoproj.io/secret-type: cluster` label
4. Argo CD (running on **Argo CD Cluster**) assumes the IAM role specified in `roleARN`
5. The assumed role is used to authenticate to the **Remote Cluster** (EKS cluster)

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

**Scenario**: Register a production EKS cluster named `production-cluster` in account `111122223333`.

**Step 1**: Create IAM role `ArgoCDEKSRole` with trust policy allowing Argo CD to assume it.

**Step 2**: Configure EKS cluster access (on remote cluster):

```bash
aws eks create-access-entry \
  --cluster-name production-cluster \
  --principal-arn arn:aws:iam::111122223333:role/ArgoCDEKSRole \
  --type STANDARD \
  --region us-west-2

aws eks associate-access-policy \
  --cluster-name production-cluster \
  --principal-arn arn:aws:iam::111122223333:role/ArgoCDEKSRole \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-west-2
```

**Step 3**: Create cluster secret file (on Argo CD cluster via Git):

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
        "roleARN": "arn:aws:iam::111122223333:role/ArgoCDEKSRole"
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

**Step 4**: Verify:

```bash
# Check secret exists
kubectl get secret production-cluster -n argocd

# Verify in Argo CD UI: Settings → Clusters
```

## Cross-Account and Cross-Region Clusters

For clusters in different AWS accounts or regions:

1. **Configure IAM Role Trust Policy** (AWS IAM):
   - **Where**: AWS IAM Console/CLI (role in remote cluster's account)
   - Allow the Argo CD account's IAM role/service account to assume the role
   - Configure cross-account trust if needed

2. **Configure EKS Cluster Access** (Remote Cluster):
   - **Where**: **Remote Cluster** (different AWS account/region)
   - Add the IAM role to the remote cluster's aws-auth ConfigMap
   - Or create EKS access entries on the remote cluster

3. **Create Cluster Secret** (Argo CD Cluster):
   - **Where**: **Argo CD Cluster** (via Git commit)
   - Use the full Kubernetes API server URL (includes region)
   - The `roleARN` should point to the role in the remote cluster's account

**Example Cross-Account Setup**:

```yaml
# Cluster secret for cross-account cluster
apiVersion: v1
kind: Secret
metadata:
  name: cross-account-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    cluster.type: application  # or "platform" for DevOps clusters
    kubernetes.io/environment: production  # Optional: development, staging, production
type: Opaque
stringData:
  name: cross-account-cluster
  server: https://<cluster-id>.gr7.<region>.eks.amazonaws.com
  config: |
    {
      "awsAuthConfig": {
        "clusterName": "remote-cluster",
        "roleARN": "arn:aws:iam::<REMOTE_ACCOUNT_ID>:role/ArgoCDEKSRole"  # Role in remote account
      },
      "tlsClientConfig": {
        "insecure": false
      }
    }
```

## Private Clusters

For private EKS clusters, ensure:
- VPC peering or VPN connectivity between Argo CD cluster and remote cluster (if needed)
- Private endpoint is accessible or public endpoint is whitelisted
- Network policies allow traffic from Argo CD cluster

The authentication method using `roleARN` works the same regardless of cluster visibility.

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
# Verify IAM role is in aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml | grep -A 5 <IAM_ROLE_NAME>

# Or verify access entry exists
aws eks describe-access-entry \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME> \
  --region <region>

# Verify access policy is associated
aws eks list-associated-access-policies \
  --cluster-name <cluster-name> \
  --principal-arn arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME> \
  --region <region>
```

## Usage with ApplicationSets

Once clusters are registered, use them in ApplicationSets:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps-production
  namespace: argocd
spec:
  generators:
    - clusters:
        selector:
          matchLabels:
            argocd.argoproj.io/secret-type: cluster
            cluster.type: application  # Select application clusters
            kubernetes.io/environment: production  # Matches label from secret
  template:
    metadata:
      name: "{{name}}-app"  # {{name}} = cluster name (e.g., "eks-cluster-name-for-argo")
      labels:
        cluster: "{{name}}"  # Can use cluster name for labels
    spec:
      project: default
      source:
        repoURL: https://github.com/example/apps.git
        targetRevision: HEAD
        path: apps/myapp
      destination:
        # {{server}} contains the Kubernetes API server URL
        server: "{{server}}"  # e.g., "https://xxxyyyzzz.xyz.some-region.eks.amazonaws.com"
        namespace: default
```

**Available Template Variables**:
- `{{name}}` - Cluster name from secret (e.g., `"eks-cluster-name-for-argo"`)
  - Use for: Application names, labels, metadata, annotations
  - **Cannot use** for `destination.server` (requires URL)
- `{{server}}` - Kubernetes API server URL from secret (e.g., `"https://xxxyyyzzz.xyz.some-region.eks.amazonaws.com"`)
  - **Must use** for `destination.server` field
  - Contains the full API server URL

**Note**: You **must** use `{{server}}` in `destination.server` because it contains the Kubernetes API server URL. Using `{{name}}` (just the cluster name) will not work.

## Resources

- [Argo CD Declarative Setup - EKS](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#eks)
- [EKS Access Entries](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [EKS aws-auth ConfigMap](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
