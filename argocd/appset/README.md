# ApplicationSet Configuration

ApplicationSets automatically discover and deploy applications based on directory structure and cluster configurations.

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
Sequential bootstrap components:
- `01-bootstrap-prometheus.yml` - Monitoring stack
- `02-bootstrap-core.yml` - Gateway and monitoring
- `03-bootstrap-vault-agent-injector.yml` - Secret management

## Key Features

- ✅ **Automated Discovery**: Find applications from directory structure
- ✅ **Multi-Cluster**: Deploy to multiple clusters with matrix generators
- ✅ **Image Updates**: Automatic container image updates (dev only)
- ✅ **Git Write-Back**: Auto-commit image updates to Git

## Usage

```bash
# List ApplicationSets
kubectl get applicationsets -n argocd

# List generated applications
argocd app list --appset apps-dev

# Sync application
argocd app sync docker-desktop-default-webapp
```

## Reference

- [ApplicationSet Docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/)
- [Git Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Git/)
- [Cluster Generator](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Cluster/)
