# Infrastructure Configuration

Infrastructure components, ArgoCD Image Updater, and sync policies for the GitOps environment.

## Table of Contents

- [Core Components](#core-components)
- [ArgoCD Image Updater](#argocd-image-updater)
- [Setup](#setup)
- [Examples](#examples)
- [Reference](#reference)

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

- **Automatic Monitoring**: Polls registries for new tags
- **Git Write-Back**: Commits changes to Git via SSH
- **Tag Filtering**: Regex patterns for tag selection
- **Helm Integration**: Updates Helm chart values

## Setup

### Prerequisites

- ArgoCD Image Updater installed
- SSH key for Git write-back operations

### Create Git Credentials Secret

```bash
# Create SSH secret for Git write-back
kubectl -n argocd create secret generic git-creds \
  --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
```

### Verify Setup

```bash
# Check Image Updater is running
kubectl get pods -n argocd | grep image-updater

# Check secret exists
kubectl get secret git-creds -n argocd
```

## Examples

### Enabling Image Updates for an Application

Add annotations to your Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  annotations:
    argocd-image-updater.argoproj.io/image-list: app=ghcr.io/org/app
    argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
    argocd-image-updater.argoproj.io/app.update-strategy: newest-build
    argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
    argocd-image-updater.argoproj.io/git-repository: git@github.com:org/repo.git
```

## Reference

- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)
