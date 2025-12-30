# Infrastructure Configuration

Infrastructure components, ArgoCD Image Updater, and sync policies for the GitOps environment.

## Core Components

### Cluster Bootstrap (`cluster-bootstrap/`)
- **`core/`**: Gateway (Kong), monitoring (Blackbox Exporter)
- **`prometheus/`**: Prometheus monitoring stack
- **`vault-agent-injector/`**: Vault integration

### Cluster Resources (`clusters/in-cluster/`)
- **`argocd/`**: Image updater, RBAC operator
- **`databases/`**: Redis
- **`monitoring/`**: Prometheus
- **`secret-manager/`**: Vault

## ArgoCD Image Updater

### Configuration

Automatic container image updates with Git write-back:

```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: app=ghcr.io/org/app
  argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
  argocd-image-updater.argoproj.io/app.update-strategy: newest-build
  argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
  argocd-image-updater.argoproj.io/git-repository: git@github.com:org/repo.git
```

### Features

- ✅ **Automatic Monitoring**: Polls registries for new tags
- ✅ **Git Write-Back**: Commits changes to Git via SSH
- ✅ **Tag Filtering**: Regex patterns for tag selection
- ✅ **Helm Integration**: Updates Helm chart values

## Setup

```bash
# Create SSH secret for Git write-back
kubectl -n argocd create secret generic git-creds \
  --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
```

## Reference

- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)
