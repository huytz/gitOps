# Infrastructure Configuration

This directory contains infrastructure components, ArgoCD Image Updater configuration, and sync policies for the GitOps environment.

## Overview

The infrastructure layer provides:
- **🔧 ArgoCD Image Updater**: Automatic container image updates
- **🔄 Sync Policies**: Automated application synchronization
- **🏗️ Infrastructure Components**: Monitoring, databases, and secret management
- **⚙️ Configuration Management**: Helm charts and values

## Infrastructure Structure

### Cluster Bootstrap
- **`cluster-bootstrap/`**: Cluster-level infrastructure components
  - **`core/`**: Core infrastructure (gateway, monitoring)
  - **`prometheus/`**: Prometheus monitoring stack
  - **`vault-agent-injector/`**: Vault integration

### Cluster-Specific Resources
- **`clusters/`**: Cluster-specific configurations
  - **`in-cluster/`**: In-cluster resources
    - **`argocd/`**: ArgoCD components (image updater, RBAC operator)
    - **`databases/`**: Database components (Redis)
    - **`monitoring/`**: Monitoring stack (Prometheus)
    - **`secret-manager/`**: Secret management (Vault)

## 🔧 ArgoCD Image Updater

### Configuration

The ArgoCD Image Updater automatically updates container images in applications based on configured policies.

#### **Global Configuration**
```yaml
# infrastructure/clusters/in-cluster/argocd/argocd-image-updater/values.yaml
config:
  applicationsAPIKind: "kubernetes"
  disableKubeEvents: false
  
  # Git commit configuration
  gitCommitUser: "huytz"
  gitCommitTemplate: |
    build: automatic update of {{ .AppName }}

    {{ range .AppChanges -}}
    updates image {{ .Image }} tag to '{{ .NewTag }}'
    {{ end -}}
  
  # Platform preferences
  platforms: "linux/amd64"
  
  # Logging
  logLevel: "debug"
  
  # SSH configuration
  sshConfig:
    config: |
      Host *
        PubkeyAcceptedAlgorithms +ssh-rsa
        HostkeyAlgorithms +ssh-rsa
```

#### **Application-Level Configuration**
```yaml
# Example from apps-prod ApplicationSet
metadata:
  annotations:
    # Image list and filtering (commented out for manual control)
    argocd-image-updater.argoproj.io/image-list: app=ghcr.io/huytz/{{.path.basename}}
    argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
    argocd-image-updater.argoproj.io/app.update-strategy: newest-build
    argocd-image-updater.argoproj.io/app.platform: linux/amd64
    
    # Helm integration
    argocd-image-updater.argoproj.io/app.helm.image-name: containerImage.repository
    argocd-image-updater.argoproj.io/app.helm.image-tag: containerImage.tag
    
    # Git write-back configuration
    argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
    argocd-image-updater.argoproj.io/git-branch: main
    argocd-image-updater.argoproj.io/git-repository: git@github.com:huytz/gitops.git
    argocd-image-updater.argoproj.io/write-back-target: "helmvalues:/{{.path.path}}/values.yaml"
```

#### **Update Strategies**
- **`newest-build`**: Uses image creation timestamps (requires metadata) - **Currently Used**
- **`alphabetical`**: Sorts tags alphabetically and picks the last one
- **`semver`**: Semantic versioning-based updates
- **`digest`**: Updates to the most recent digest of a mutable tag

#### **Features**
- ✅ **Automatic Image Monitoring**: Polls container registries for new image tags
- ✅ **Git Write-Back**: Commits changes directly to Git repositories using SSH
- ✅ **Platform Compatibility**: Handles multi-platform image manifests
- ✅ **Tag Filtering**: Supports regex patterns for tag selection (e.g., `^main-[0-9a-f]{7}$`)
- ✅ **Helm Integration**: Updates Helm chart values automatically
- ✅ **SSH Authentication**: Secure Git access with SSH key configuration
- ✅ **Force Updates**: Enables forced updates for development environments

### Complete Workflow Example

This example demonstrates the complete automated workflow from a commit to the [webapp repository](https://github.com/huytz/webapp) to automatic deployment:

#### **1. Application Configuration**
```yaml
# apps/production/in-cluster/default/webapp/values.yaml
applicationName: webapp
replicaCount: 1
containerImage:
  repository: ghcr.io/huytz/webapp
  tag: main-e785142  # Current image tag
  pullPolicy: IfNotPresent
containerPort: 3000
service:
  type: ClusterIP
  port: 3000
ingress:
  enabled: false
serviceAccount:
  create: true
  name: webapp
```

#### **2. GitHub Actions Workflow (in webapp repo)**
```yaml
# .github/workflows/build-and-push.yml
name: Build and Push Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ghcr.io/huytz/webapp:main-${{ github.sha }}
            ghcr.io/huytz/webapp:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

#### **3. Automatic Update Process**

1. **Developer pushes to main branch** in [webapp repository](https://github.com/huytz/webapp)
2. **GitHub Actions builds and pushes** new image with tag `main-<commit-hash>`
3. **ArgoCD Image Updater detects** new image tag matching pattern `^main-[0-9a-f]{7}$` and selects the newest build
4. **Image updater updates** the `values.yaml` file with new tag
5. **Git commit is created** automatically with message:
   ```
   build: automatic update of webapp

   updates image ghcr.io/huytz/webapp tag to 'main-abc1234'
   ```
6. **ArgoCD syncs** the application with new image
7. **Application deploys** with updated image

#### **4. Example Update Flow**
```bash
# Before update
containerImage:
  repository: ghcr.io/huytz/webapp
  tag: main-e785142

# After new commit (abc1234) to webapp repo
containerImage:
  repository: ghcr.io/huytz/webapp
  tag: main-abc1234  # Automatically updated
```

#### **5. Monitoring the Process**
```bash
# Check image updater logs
kubectl logs -n argocd deployment/argocd-image-updater

# Check application sync status
argocd app get webapp -o yaml

# View recent commits in gitops repo
git log --oneline -10
```

## 🔄 Sync Policy

All applications use automated sync policies with:
- **Prune**: Automatically removes resources when they're no longer in Git
- **Self-Heal**: Automatically corrects drift from the desired state
- **CreateNamespace**: Automatically creates namespaces if they don't exist
- **Sync Options**: 
  - `ServerSideApply=true`: Uses server-side apply for better conflict resolution
  - `CreateNamespace=true`: Creates namespaces automatically

### StatefulSet Sync Optimization

The Infrastructure ApplicationSet includes optimized sync settings for StatefulSets:

```yaml
# argocd/appset/infrastructure.yml
ignoreDifferences:
  - group: apps
    kind: StatefulSet
    jqPathExpressions:
      - .spec.volumeClaimTemplates[].apiVersion
      - .spec.volumeClaimTemplates[].kind
```

## Best Practices

### Image Update Configuration
1. **Use Specific Tag Patterns**: `regexp:^main-[0-9a-f]{7}$` for commit-based tags
2. **Choose Appropriate Strategy**: `newest-build` for timestamps (currently used), `alphabetical` for commit hashes
3. **Enable Force Updates**: `force-update: "true"` for development environments
4. **Configure Platform**: Specify platform when using `newest-build` strategy

### Git Write-Back
1. **Use SSH Authentication**: Configure SSH keys for secure Git access
2. **Set Commit User**: Configure `gitCommitUser` for proper attribution
3. **Custom Commit Messages**: Use templates for consistent commit messages

### SSH Key Configuration
```bash
# Create the SSH secret for ArgoCD Image Updater
kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"

# Verify the secret was created
kubectl -n argocd get secret git-creds

# If you need to use a different SSH key
kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="/path/to/your/private/key"
```

**Note**: Make sure your SSH key has access to the Git repository and is added to your GitHub account.

## Infrastructure Components

### Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Blackbox Exporter**: Uptime monitoring

### Database Components
- **Redis**: Caching and session storage
- **PostgreSQL**: Primary database (if needed)

### Secret Management
- **Vault**: Secret storage and management
- **Vault Agent Injector**: Automatic secret injection

### Gateway Components
- **Kong Ingress**: API gateway and load balancing

## Usage

### Deploying Infrastructure
```bash
# Infrastructure is automatically deployed via ApplicationSets
# Check infrastructure applications
argocd app list --appset infrastructure

# Sync infrastructure components
argocd app sync in-cluster-prometheus
argocd app sync in-cluster-vault
```

### Monitoring Infrastructure
```bash
# Check infrastructure component status
kubectl get pods -n monitoring
kubectl get pods -n vault
kubectl get pods -n kong-system

# View infrastructure logs
kubectl logs -n monitoring deployment/prometheus-server
kubectl logs -n vault deployment/vault
```

### Troubleshooting
```bash
# Check infrastructure ApplicationSet
kubectl describe applicationset infrastructure -n argocd

# Verify infrastructure configurations
kubectl get configmaps -n argocd -l app.kubernetes.io/part-of=argocd

# Check infrastructure sync status
argocd app list --appset infrastructure --output wide
```

## Reference

- [ArgoCD Image Updater Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-image-updater/)
- [ArgoCD Sync Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)
- [Helm Charts](https://helm.sh/docs/)
- [Kubernetes StatefulSets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
