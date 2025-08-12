# GitOps Repository

A comprehensive GitOps implementation using **ArgoCD** for managing Kubernetes clusters with automated deployments, continuous monitoring, and infrastructure as code practices.

## 🎯 Overview

A **production-ready GitOps workflow** using ArgoCD for automated Kubernetes deployments with:

- 🚀 **Multi-environment applications** (dev/prod)
- 🏗️ **Infrastructure as Code** (monitoring, databases, secrets)
- 🔄 **Auto image updates** with ArgoCD Image Updater
- 🔐 **Security** (RBAC, Vault, secure Git workflows)
- 📊 **Observability** (Prometheus, Grafana)

### ✨ Key Features

- **🔧 One-command setup**: `make local` for complete local environment
- **🔄 Declarative management**: GitOps workflow with ArgoCD
- **📦 Multi-environment**: Separate dev/prod configurations
- **🖼️ Auto deployments**: Continuous image updates
- **🔐 Security-first**: RBAC and secrets management

## 🏗️ Repository Structure

```
gitops/
├── _bootstraps/                   # Bootstrap configuration
│   ├── argocd.yml                # ArgoCD Helm values
│   └── root/                     # Root ArgoCD applications
│       ├── root-argocd-appset.yml
│       ├── root-argocd-rbac.yml
│       └── root-projects.yml
├── argocd/                       # ArgoCD configuration
│   ├── appset/                   # ApplicationSet definitions
│   │   ├── 01-bootstrap-prometheus.yml
│   │   ├── 02-bootstrap-core.yml
│   │   ├── 03-bootstrap-vault-agent-injector.yml
│   │   ├── apps-dev.yml
│   │   ├── apps-prod.yml
│   │   └── infrastructure.yml
│   ├── projects/                 # ArgoCD project definitions
│   │   ├── apps-dev.yml
│   │   ├── apps-prod.yml
│   │   └── infrastructure.yml
│   └── rbac/                     # RBAC configuration
│       └── image-updater.yml
├── apps/                         # Application configurations
│   ├── development/              # Development applications
│   │   └── default/
│   │       └── webapp/
│   │           └── values.yaml
│   └── production/               # Production applications
│       └── in-cluster/
│           └── default/
│               └── webapp/
│                   └── values.yaml
├── infrastructure/               # Infrastructure components
│   ├── cluster-bootstrap/        # Cluster-level bootstrap
│   │   ├── core/                 # Core infrastructure
│   │   │   ├── gateway/          # Gateway components
│   │   │   │   └── kong-ingress/
│   │   │   └── monitor/          # Monitoring components
│   │   │       └── blackbox-exporter/
│   │   ├── prometheus/           # Prometheus monitoring
│   │   └── vault-agent-injector/ # Vault integration
│   └── clusters/                 # Cluster-specific configurations
│       └── in-cluster/           # In-cluster resources
│           ├── argocd/           # ArgoCD components
│           │   ├── argocd-image-updater/
│           │   └── argocd-rbac-operator/
│           ├── databases/        # Database components
│           │   └── redis/
│           ├── monitoring/       # Monitoring stack
│           │   └── prometheus/
│           └── secret-manager/   # Secret management
│               └── vault/
├── Makefile                      # Automation scripts
└── README.md                     # This file
```

## 🚀 Getting Started

### Prerequisites

- **Docker Desktop** with Kubernetes enabled
- **Helm** (v3.x) installed
- **kubectl** configured for docker-desktop context
- **Git** for repository access

### Local Development Setup

The repository includes a comprehensive Makefile for easy local development setup.

#### **Quick Start (Recommended)**

Run the complete setup in one command:

```bash
make local
```

This will:
1. ✅ Check all prerequisites (Helm, kubectl, docker-desktop context)
2. ✅ Install ArgoCD with HA configuration
3. ✅ Apply bootstrap manifests
4. 📋 Provide next steps for accessing ArgoCD UI

#### **Manual Setup Stages**

If you prefer to run stages individually:

```bash
# 1. Check prerequisites only
make pre_check

# 2. Install ArgoCD only
make argocd-install

# 3. Apply bootstrap configuration only
make init
```

#### **Post-Setup Steps**

After running `make local`, access your GitOps environment:

1. **Start port-forwarding**:
   ```bash
   kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
   ```

2. **Get admin password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Access ArgoCD UI**:
   - URL: https://localhost:8080
   - Username: `admin`
   - Password: (from step 2)

4. **Configure ArgoCD Image Updater SSH Secret** (for automatic image updates):
   ```bash
   kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
   ```
   This enables the ArgoCD Image Updater to commit changes back to the Git repository.

5. **Add Production Environment Label** (for automated infrastructure deployment):
   - In ArgoCD UI, go to **Settings** → **Clusters**
   - Select your cluster (usually `in-cluster` or `docker-desktop`)
   - Add label: `kubernetes.io/environment: production`
   - This enables automatic deployment of infrastructure components from `infrastructure/clusters/in-cluster`


#### **Verify Deployment**

```bash
# List all ArgoCD applications
argocd app list

# Check ArgoCD server status
kubectl get pods -n argocd
```

## 📋 ApplicationSets

### Overview

Applications are managed through ApplicationSets that automatically discover and deploy applications based on the directory structure:

- **Apps-Prod ApplicationSet** (`argocd/appset/apps-prod.yml`): Production applications
- **Apps-Dev ApplicationSet** (`argocd/appset/apps-dev.yml`): Development applications with automatic image updates
- **Infrastructure ApplicationSet** (`argocd/appset/infrastructure.yml`): Infrastructure components
- **Bootstrap ApplicationSets** (`argocd/appset/01-*.yml`): Cluster-level bootstrap components

### Apps-Dev ApplicationSet

The `apps-dev` ApplicationSet manages development applications with automatic image updates:

#### **Configuration**
```yaml
# argocd/appset/apps-dev.yml
spec:
  generators:
    - matrix:
        generators:
          - git:
              repoURL: https://github.com/huytz/gitops.git
              directories:
                - path: apps/development/*/*
          - clusters:
              selector:
                matchLabels:
                  kubernetes.io/environment: 'development'
  template:
    metadata:
      annotations:
        # Image updater annotations
        argocd-image-updater.argoproj.io/image-list: app=ghcr.io/huytz/{{.path.basename}}
        argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
        argocd-image-updater.argoproj.io/app.update-strategy: newest-build
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

#### **Naming Convention & Examples**
- **Template**: `{{.name}}-{{index .path.segments 2}}-{{.path.basename}}`
- **Path**: `apps/development/*/*` → `apps/development/default/webapp`
- **Output**: `docker-desktop-default-webapp`

#### **Features**
- ✅ **Multi-Cluster Support**: Matrix generator for multiple development clusters
- ✅ **Automatic Image Updates**: Monitors container registries for new image tags
- ✅ **Tag Filtering**: Only updates to `main-*` tags matching 7-character hex commit hashes
- ✅ **Newest Build Strategy**: Updates to the most recently built image based on creation timestamp
- ✅ **Git Write-Back**: Automatically commits changes to the Git repository
- ✅ **Platform Compatibility**: Configured for `linux/amd64` platform
- ✅ **Helm Integration**: Uses `k8s-service` chart with custom values

### Apps-Prod ApplicationSet

The `apps-prod` ApplicationSet manages production applications:

#### **Configuration**
```yaml
# argocd/appset/apps-prod.yml
spec:
  generators:
    - matrix:
        generators:
          - git:
              repoURL: https://github.com/huytz/gitops.git
              directories:
                - path: apps/production/*/*/*
          - clusters:
              selector:
                matchLabels:
                  kubernetes.io/environment: production
  template:
    metadata:
      name: 'prod-{{.name}}-{{index .path.segments 2}}-{{.path.basename}}'
```

#### **Naming Convention & Examples**
- **Template**: `prod-{{.name}}-{{index .path.segments 2}}-{{.path.basename}}`
- **Path**: `apps/production/*/*/*` → `apps/production/in-cluster/default/webapp`
- **Output**: `prod-in-cluster-default-webapp`

#### **Features**
- ✅ **Multi-Cluster Support**: Matrix generator for multiple production clusters
- ✅ **Production Environment**: Deploys to production-labeled clusters
- ✅ **Helm Integration**: Uses `k8s-service` chart with custom values
- ✅ **Automated Sync**: Prune and self-heal enabled
- ⏸️ **Manual Image Updates**: Image updater annotations commented out for manual control

### Infrastructure ApplicationSet

The `infrastructure` ApplicationSet manages infrastructure components:

#### **Configuration**
```yaml
# argocd/appset/infrastructure.yml
spec:
  generators:
    - matrix:
        generators:
          - git:
              files:
                - path: infrastructure/clusters/*/*/charts.yaml
              repoURL: https://github.com/huytz/gitops.git
          - clusters:
              selector:
                matchLabels:
                  kubernetes.io/environment: production
  template:
    metadata:
      name: "{{.name}}-{{.path.basename}}"
```

#### **Naming Convention & Examples**
- **Template**: `{{.name}}-{{.path.basename}}`
- **Path**: `infrastructure/clusters/*/*/charts.yaml` → `infrastructure/clusters/in-cluster/argocd/argocd-image-updater/charts.yaml`
- **Output**: `in-cluster-argocd-image-updater`

#### **Features**
- ✅ **Dynamic Chart Discovery**: Uses `charts.yaml` files for chart configuration
- ✅ **Multi-Cluster Support**: Matrix generator for multiple production clusters
- ✅ **StatefulSet Optimization**: Ignores volumeClaimTemplates differences
- ✅ **Automated Sync**: Prune and self-heal enabled

### Bootstrap ApplicationSets

Sequential bootstrap components for cluster initialization:

#### **Naming Convention & Examples**
- **Template**: `{{.name}}-bootstrap-{{.path.basename}}`
- **Examples**:
  - `01-bootstrap-prometheus.yml` → `in-cluster-bootstrap-prometheus`
  - `02-bootstrap-core.yml` → `in-cluster-bootstrap-kong-ingress`
  - `03-bootstrap-vault-agent-injector.yml` → `in-cluster-bootstrap-vault-agent-injector`

#### **Components**
- **`01-bootstrap-prometheus.yml`**: Prometheus monitoring stack
- **`02-bootstrap-core.yml`**: Core infrastructure components (gateway, monitoring)
- **`03-bootstrap-vault-agent-injector.yml`**: Vault integration

## 🔄 Automatic Image Update Example

### Complete Workflow: Webapp Repository

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
    # argocd-image-updater.argoproj.io/image-list: app=ghcr.io/huytz/{{.path.basename}}
    # argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
    # argocd-image-updater.argoproj.io/app.update-strategy: newest-build
    # argocd-image-updater.argoproj.io/app.platform: linux/amd64
    
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

### Best Practices

#### **Image Update Configuration**
1. **Use Specific Tag Patterns**: `regexp:^main-[0-9a-f]{7}$` for commit-based tags
2. **Choose Appropriate Strategy**: `newest-build` for timestamps (currently used), `alphabetical` for commit hashes
3. **Enable Force Updates**: `force-update: "true"` for development environments
4. **Configure Platform**: Specify platform when using `newest-build` strategy

#### **Git Write-Back**
1. **Use SSH Authentication**: Configure SSH keys for secure Git access
2. **Set Commit User**: Configure `gitCommitUser` for proper attribution
3. **Custom Commit Messages**: Use templates for consistent commit messages

#### **SSH Key Configuration**
```bash
# Create the SSH secret for ArgoCD Image Updater
kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"

# Verify the secret was created
kubectl -n argocd get secret git-creds

# If you need to use a different SSH key
kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="/path/to/your/private/key"
```

**Note**: Make sure your SSH key has access to the Git repository and is added to your GitHub account.

