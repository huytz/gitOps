# ArgoCD ApplicationSet Configuration

This directory contains ApplicationSet definitions that automatically discover and deploy applications based on directory structure and cluster configurations.

## Overview

ApplicationSets provide:
- **Automated Discovery**: Automatically find applications based on directory structure
- **Multi-Cluster Deployment**: Deploy to multiple clusters with matrix generators
- **Dynamic Configuration**: Generate applications from Git repositories
- **Consistent Patterns**: Standardized application naming and configuration

## ApplicationSet Structure

### Application ApplicationSets

#### `apps-dev.yml`
Development applications with automatic image updates:
- **Generator**: Matrix of Git directories and development clusters
- **Path Pattern**: `apps/development/*/*`
- **Features**: Automatic image updates, Git write-back, newest-build strategy
- **Naming**: `{{.name}}-{{index .path.segments 2}}-{{.path.basename}}`

**Key Features**:
- ✅ Multi-cluster support for development environments
- ✅ Automatic image updates with ArgoCD Image Updater
- ✅ Tag filtering for `main-*` commit-based tags
- ✅ Git write-back for automatic commits
- ✅ Platform compatibility for `linux/amd64`

#### `apps-prod.yml`
Production applications with manual control:
- **Generator**: Matrix of Git directories and production clusters
- **Path Pattern**: `apps/production/*/*/*`
- **Features**: Manual image updates, production safety controls
- **Naming**: `prod-{{.name}}-{{index .path.segments 2}}-{{.path.basename}}`

**Key Features**:
- ✅ Multi-cluster support for production environments
- ✅ Manual image update control for production safety
- ✅ Production environment validation
- ✅ Automated sync with prune and self-heal

### Infrastructure ApplicationSet

#### `infrastructure.yml`
Infrastructure components with dynamic chart discovery:
- **Generator**: Matrix of chart files and production clusters
- **Path Pattern**: `infrastructure/clusters/*/*/charts.yaml`
- **Features**: Dynamic chart discovery, StatefulSet optimization
- **Naming**: `{{.name}}-{{.path.basename}}`

**Key Features**:
- ✅ Dynamic chart discovery using `charts.yaml` files
- ✅ StatefulSet volume claim template optimization
- ✅ Infrastructure-specific configurations
- ✅ Automated sync for infrastructure components

### Bootstrap ApplicationSets

Sequential bootstrap components for cluster initialization:

#### `01-bootstrap-prometheus.yml`
Prometheus monitoring stack:
- **Purpose**: Cluster-level monitoring infrastructure
- **Naming**: `{{.name}}-bootstrap-prometheus`
- **Order**: First bootstrap component

#### `02-bootstrap-core.yml`
Core infrastructure components:
- **Purpose**: Gateway and monitoring components
- **Components**: Kong Ingress, Blackbox Exporter
- **Naming**: `{{.name}}-bootstrap-{{.path.basename}}`
- **Order**: Second bootstrap component

#### `03-bootstrap-vault-agent-injector.yml`
Vault integration:
- **Purpose**: Secret management integration
- **Naming**: `{{.name}}-bootstrap-vault-agent-injector`
- **Order**: Third bootstrap component

## Configuration Examples

### Development ApplicationSet Configuration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps-dev
  namespace: argocd
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
      name: '{{.name}}-{{index .path.segments 2}}-{{.path.basename}}'
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
    spec:
      project: apps-dev
      source:
        repoURL: https://github.com/huytz/gitops.git
        targetRevision: main
        path: {{.path.path}}
        helm:
          valueFiles:
            - values.yaml
      destination:
        server: {{.server}}
        namespace: {{.path.segments.[1]}}-{{.path.segments.[2]}}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - ServerSideApply=true
          - CreateNamespace=true
```

### Production ApplicationSet Configuration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps-prod
  namespace: argocd
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
    spec:
      project: apps-prod
      source:
        repoURL: https://github.com/huytz/gitops.git
        targetRevision: main
        path: {{.path.path}}
        helm:
          valueFiles:
            - values.yaml
      destination:
        server: {{.server}}
        namespace: {{.path.segments.[1]}}-{{.path.segments.[2]}}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - ServerSideApply=true
          - CreateNamespace=true
```

## Naming Conventions

### Development Applications
- **Template**: `{{.name}}-{{index .path.segments 2}}-{{.path.basename}}`
- **Example Path**: `apps/development/default/webapp`
- **Output**: `docker-desktop-default-webapp`

### Production Applications
- **Template**: `prod-{{.name}}-{{index .path.segments 2}}-{{.path.basename}}`
- **Example Path**: `apps/production/in-cluster/default/webapp`
- **Output**: `prod-in-cluster-default-webapp`

### Infrastructure Components
- **Template**: `{{.name}}-{{.path.basename}}`
- **Example Path**: `infrastructure/clusters/in-cluster/argocd/argocd-image-updater/charts.yaml`
- **Output**: `in-cluster-argocd-image-updater`

### Bootstrap Components
- **Template**: `{{.name}}-bootstrap-{{.path.basename}}`
- **Examples**:
  - `01-bootstrap-prometheus.yml` → `in-cluster-bootstrap-prometheus`
  - `02-bootstrap-core.yml` → `in-cluster-bootstrap-kong-ingress`

## Best Practices

### Application Discovery
1. **Consistent Directory Structure**: Use predictable path patterns
2. **Clear Naming**: Use descriptive directory and file names
3. **Environment Separation**: Separate development and production paths
4. **Version Control**: Include all configurations in Git

### Multi-Cluster Deployment
1. **Cluster Labeling**: Use consistent cluster labels
2. **Environment Matching**: Match applications to appropriate environments
3. **Namespace Isolation**: Use separate namespaces per environment
4. **Resource Limits**: Consider cluster capacity and resource limits

### Image Updates
1. **Tag Patterns**: Use consistent tag patterns for filtering
2. **Update Strategies**: Choose appropriate update strategies
3. **Git Write-Back**: Configure secure Git access for automatic commits
4. **Force Updates**: Use force updates carefully in development

### Sync Policies
1. **Automated Sync**: Enable for development, manual for production
2. **Prune and Self-Heal**: Enable for automatic drift correction
3. **Server-Side Apply**: Use for better conflict resolution
4. **Namespace Creation**: Enable automatic namespace creation

## Usage

### Creating New ApplicationSets
1. Define the application discovery pattern
2. Configure generators (Git, clusters, etc.)
3. Set up template with appropriate metadata and spec
4. Configure sync policies and options
5. Apply the ApplicationSet configuration

### Managing Applications
```bash
# List all ApplicationSets
kubectl get applicationsets -n argocd

# Get ApplicationSet details
kubectl get applicationset apps-dev -n argocd -o yaml

# List generated applications
argocd app list --appset apps-dev

# Sync specific application
argocd app sync docker-desktop-default-webapp
```

### Troubleshooting
```bash
# Check ApplicationSet status
kubectl describe applicationset apps-dev -n argocd

# Check generated applications
kubectl get applications -n argocd -l app.kubernetes.io/instance=apps-dev

# View ApplicationSet logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller
```

## Reference

- [ApplicationSet Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [Git Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/)
- [Cluster Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/)
- [Matrix Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Matrix/)
