# ApplicationSet Configuration

ApplicationSets automatically discover and deploy applications based on directory structure and cluster configurations.

## Table of Contents

- [Core ApplicationSets](#core-applicationsets)
- [Key Features](#key-features)
- [Usage](#usage)
- [Examples](#examples)
- [Reference](#reference)

## Core ApplicationSets

### `apps-dev.yml`
Development applications with automatic image updates:
- **Path**: `apps/development/*/*`
- **Features**: Auto image updates, Git write-back, newest-build strategy
- **Tag Pattern**: `^develop-[0-9a-f]{7}$`

### `apps-prod.yml`
Production applications:
- **Path**: `apps/production/*/*/*`
- **Features**: Manual control, production safety
- **Tag Pattern**: `^main-[0-9a-f]{7}$`

### `infrastructure.yml`
Infrastructure components:
- **Path**: `infrastructure/clusters/*/*/values.yaml`
- **Features**: Dynamic chart discovery, StatefulSet optimization

### Bootstrap ApplicationSets
Sequential bootstrap components (deploy only to application clusters with labels):
- `01-bootstrap-prometheus.yml` - Monitoring stack (requires `cluster.type: application` and `cluster.bootstrap.prometheus: "true"`)
- `02-bootstrap-core.yml` - Gateway and monitoring (requires `cluster.type: application` and `cluster.bootstrap.core: "true"`)
- `03-bootstrap-vault-agent-injector.yml` - Secret management (requires `cluster.type: application` and `cluster.bootstrap.vault-agent-injector: "true"`)

## Key Features

- **Automated Discovery**: Find applications from directory structure
- **Multi-Cluster**: Deploy to multiple clusters with matrix generators
- **Image Updates**: Automatic container image updates (dev only)
- **Git Write-Back**: Auto-commit image updates to Git

## Usage

```bash
# List ApplicationSets
kubectl get applicationsets -n argocd

# List generated applications
argocd app list --appset apps-dev

# Sync application
argocd app sync docker-desktop-default-webapp
```

## Examples

### Adding a New Application

To add a new application, create the directory structure:

```bash
# Development application
mkdir -p apps/development/default/my-app
cat > apps/development/default/my-app/values.yaml <<EOF
# Your Helm values here
EOF

# Production application
mkdir -p apps/production/in-cluster/default/my-app
cat > apps/production/in-cluster/default/my-app/values.yaml <<EOF
# Your Helm values here
EOF
```

The ApplicationSet will automatically discover and deploy these applications.

### ApplicationSet Annotations

Applications can use annotations for image updates:

```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: app=ghcr.io/org/app
    argocd-image-updater.argoproj.io/app.allow-tags: regexp:^develop-[0-9a-f]{7}$
    argocd-image-updater.argoproj.io/app.update-strategy: newest-build
```

## Reference

- [ApplicationSet Docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [Git Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/)
- [Cluster Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/)
