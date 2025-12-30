# Bootstrap CI/CD Management

Automated CI/CD for managing the `_bootstraps/` directory using GitHub Actions.

## Overview

- ✅ **Version Controlled**: All bootstrap configs in Git
- ✅ **Automated Deployment**: CI applies changes via GitHub Actions
- ✅ **Self-Managing**: ArgoCD manages its own configuration
- ✅ **Automated Sync**: Periodic sync every 6 hours

## Quick Start

### Initial Setup (One-Time)

1. **Configure Self-Hosted Runner**:
   ```bash
   # Install and register runner with tags: self-hosted, local
   ./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN
   ./config.sh --labels self-hosted,local
   ```

2. **Configure GitHub Secrets** (Settings → Secrets → Actions):
   - `KUBECONFIG_DATA`: Base64 encoded kubeconfig
   - `CLUSTER_CONTEXT`: Kubernetes context (optional)

3. **Trigger First Bootstrap**:
   ```bash
   # Via CLI
   gh workflow run bootstrap-apply.yml -f cluster=docker-desktop
   
   # Or push to main (if runner ready)
   git push origin main
   ```

### After Setup: Fully Automated

```bash
# Push changes → Automatic apply
git add _bootstraps/
git commit -m "chore: update bootstrap"
git push origin main
```

## Core Workflows

### 1. Apply Workflow (`bootstrap-apply.yml`)

**Triggers**:
- **Automatic**: Push to `main` when `_bootstraps/**` changes
- **Manual**: `workflow_dispatch` with cluster/dry-run inputs

**What it does**:
1. Validates cluster access
2. Installs/upgrades ArgoCD if needed
3. Applies root applications from `_bootstraps/root/`
4. Verifies bootstrap completion

**Usage**:
```bash
# Automatic (recommended)
git push origin main

# Manual
gh workflow run bootstrap-apply.yml -f cluster=docker-desktop -f dry_run=false
```

### 2. Sync Workflow (`bootstrap-sync.yml`)

**Triggers**:
- **Automatic**: Every 6 hours (scheduled)
- **Manual**: `workflow_dispatch`

**What it does**:
- Syncs all root applications (applications, projects, rbac, notification)
- Detects and corrects drift
- Reports sync status

**Usage**:
```bash
# Automatic: Runs every 6 hours
# Manual:
gh workflow run bootstrap-sync.yml
```

## Configuration

### Required Secrets

- `KUBECONFIG_DATA`: Base64 encoded kubeconfig
- `CLUSTER_CONTEXT`: Kubernetes context (optional)

### Environment Protection

Configure in **Settings** → **Environments** → **production**:
- Required reviewers (optional)
- Deployment branches: `main` only

## Workflow Triggers

| Workflow | Automatic | Manual | Frequency |
|----------|-----------|--------|-----------|
| `bootstrap-apply.yml` | Push to `main` | `workflow_dispatch` | On-demand |
| `bootstrap-sync.yml` | Every 6h | `workflow_dispatch` | Every 6h |

## Ensuring Sync

**Check Status**:
```bash
# GitHub Actions
gh run list --workflow=bootstrap-sync.yml

# ArgoCD
kubectl get applications -n argocd
```

**Force Sync**:
```bash
# Via workflow
gh workflow run bootstrap-sync.yml

# Via ArgoCD CLI
argocd app sync argocd-applications argocd-projects argocd-rbac argocd-notification
```

## Troubleshooting

**Bootstrap Apply Fails**:
```bash
kubectl cluster-info
kubectl get pods -n argocd
kubectl apply -f _bootstraps/root/  # Manual apply
```

**Sync Fails**:
```bash
argocd version
argocd app sync argocd-applications
```

## Reference

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [ArgoCD CI/CD](https://argo-cd.readthedocs.io/en/stable/user-guide/ci_automation/)
- [Workflows README](../.github/workflows/README.md)
