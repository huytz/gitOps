# GitOps Repository

This repository contains the GitOps configuration for managing Kubernetes clusters using ArgoCD. It follows a declarative approach where all infrastructure and application configurations are version-controlled and automatically deployed.

## 🏗️ Repository Structure

```
gitops/
├── _bootstraps/                    # Root ArgoCD applications
├── argocd/                        # ArgoCD configuration
│   ├── appset/                    # ApplicationSet definitions
│   └── projects/                  # ArgoCD project definitions
├── apps/                         # Production application configurations
├── apps-dev/                     # Development application configurations
└── infrastructure/               # Infrastructure components
```

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster with ArgoCD installed
- ArgoCD CLI tools (`argocd`)
- `kubectl` configured for your cluster

### Bootstrap Process

1. **Deploy Root Applications**:

   ```bash
   kubectl apply -f _bootstraps/root-argocd-appset.yml
   kubectl apply -f _bootstraps/root-projects.yml
   ```

2. **Verify Deployment**:

   ```bash
   argocd app list
   ```

## 📋 ApplicationSets

### Overview

Applications are managed through ApplicationSets that automatically discover and deploy applications based on the directory structure:

- **Apps ApplicationSet** (`argocd/appset/apps.yml`): Production applications
- **Apps-Dev ApplicationSet** (`argocd/appset/apps-dev.yml`): Development applications with automatic image updates
- **Infrastructure ApplicationSet** (`argocd/appset/infrastructure.yml`): Infrastructure components
- **Cluster Bootstrap ApplicationSet** (`argocd/appset/cluster-bootstrap.yml`): Cluster-level components

### Apps-Dev ApplicationSet

The `apps-dev` ApplicationSet manages development applications with automatic image updates:

#### **Configuration**
```yaml
# argocd/appset/apps-dev.yml
spec:
  generators:
    - git:
        repoURL: git@github.com:huytz/gitops.git
        directories:
          - path: apps-dev
  template:
    metadata:
      annotations:
        # Image updater annotations
        argocd-image-updater.argoproj.io/image-list: app=ghcr.io/huytz/{{.path.basename}}
        argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
        argocd-image-updater.argoproj.io/app.update-strategy: alphabetical
        argocd-image-updater.argoproj.io/app.platform: linux/amd64
        argocd-image-updater.argoproj.io/app.force-update: "true"
        
        # Helm parameters
        argocd-image-updater.argoproj.io/app.helm.image-name: containerImage.repository
        argocd-image-updater.argoproj.io/app.helm.image-tag: containerImage.tag
        
        # Git write-back
        argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
        argocd-image-updater.argoproj.io/git-branch: main
        argocd-image-updater.argoproj.io/git-repository: git@github.com:huytz/gitops.git
        argocd-image-updater.argoproj.io/write-back-target: "helmvalues:/{{.path.path}}/values.yaml"
```

#### **Features**
- ✅ **Automatic Image Updates**: Monitors container registries for new image tags
- ✅ **Tag Filtering**: Only updates to `main-*` tags matching 7-character hex commit hashes
- ✅ **Alphabetical Strategy**: Updates to the latest commit hash when sorted alphabetically
- ✅ **Git Write-Back**: Automatically commits changes to the Git repository
- ✅ **Platform Compatibility**: Configured for `linux/amd64` platform

## 🔄 Automatic Image Update Example

### Complete Workflow: Webapp Repository

This example demonstrates the complete automated workflow from a commit to the [webapp repository](https://github.com/huytz/webapp) to automatic deployment:

#### **1. Application Configuration**
```yaml
# apps-dev/in-cluster/development/webapp/values.yaml
applicationName: webapp
replicaCount: 1
containerImage:
  repository: ghcr.io/huytz/webapp
  tag: main-7ceb248  # Current image tag
  pullPolicy: IfNotPresent
containerPort: 3000
service:
  type: ClusterIP
  port: 3000
ingress:
  enabled: false
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
3. **ArgoCD Image Updater detects** new image tag matching pattern `^main-[0-9a-f]{7}$`
4. **Image updater updates** the `values.yaml` file with new tag
5. **Git commit is created** automatically with message: `feat: update webapp to ghcr.io/huytz/webapp:main-abc1234 (main-7ceb248 -> main-abc1234)`
6. **ArgoCD syncs** the application with new image
7. **Application deploys** with updated image

#### **4. Example Update Flow**
```bash
# Before update
containerImage:
  repository: ghcr.io/huytz/webapp
  tag: main-7ceb248

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

## 🔧 ArgoCD Image Updater

### Configuration

The ArgoCD Image Updater automatically updates container images in applications based on configured policies.

#### **Key Configuration**
```yaml
# infrastructure/clusters/in-cluster/argocd/argocd-image-updater/values.yaml
config:
  applicationsAPIKind: "kubernetes"
  argocd:
    serverAddress: "argocd-server.argocd.svc.cluster.local:80"
    insecure: true
    plaintext: true
  
  # Git commit configuration
  gitCommitUser: "huytz"
  gitCommitTemplate: "feat: update {{.AppName}} to {{.Image}}:{{.NewTag}} ({{.OldTag}} -> {{.NewTag}})"
  
  # Platform preferences
  platforms: "linux/amd64"
  
  # Logging
  logLevel: "debug"
```

#### **Update Strategies**
- **`alphabetical`**: Sorts tags alphabetically and picks the last one
- **`newest-build`**: Uses image creation timestamps (requires metadata)
- **`semver`**: Semantic versioning-based updates
- **`digest`**: Updates to the most recent digest of a mutable tag

#### **Features**
- ✅ **Automatic Image Monitoring**: Polls container registries for new image tags
- ✅ **Git Write-Back**: Commits changes directly to Git repositories
- ✅ **Platform Compatibility**: Handles multi-platform image manifests
- ✅ **Tag Filtering**: Supports regex patterns for tag selection
- ✅ **Helm Integration**: Updates Helm chart values automatically

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

## 🔧 Troubleshooting

### ArgoCD Image Updater Issues

#### **Platform Mismatch Errors**
```
Manifest list did not contain any usable reference. Platforms requested: (darwin/arm64), platforms included: (linux/amd64,linux/arm64)
```

**Solution**: Add platform annotation to application:
```yaml
argocd-image-updater.argoproj.io/app.platform: linux/amd64
```

#### **Template Errors**
```
can't evaluate field Image in type argocd.commitMessageTemplate
```

**Solution**: Use correct template variables based on [official documentation](https://argocd-image-updater.readthedocs.io/en/stable/basics/update-methods/#changing-the-git-commit-message):
```yaml
gitCommitTemplate: "feat: update {{.AppName}} to {{.Image}}:{{.NewTag}} ({{.OldTag}} -> {{.NewTag}})"
```

### Best Practices

#### **Image Update Configuration**
1. **Use Specific Tag Patterns**: `regexp:^main-[0-9a-f]{7}$` for commit-based tags
2. **Choose Appropriate Strategy**: `alphabetical` for commit hashes, `newest-build` for timestamps
3. **Enable Force Updates**: `force-update: "true"` for development environments
4. **Configure Platform**: Specify platform when using `newest-build` strategy

#### **Git Write-Back**
1. **Use SSH Authentication**: Configure SSH keys for secure Git access
2. **Set Commit User**: Configure `gitCommitUser` for proper attribution
3. **Custom Commit Messages**: Use templates for consistent commit messages

