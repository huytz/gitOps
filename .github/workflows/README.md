# GitHub Actions Workflows

This directory contains CI/CD workflows for managing the GitOps repository.

## Workflows

### Bootstrap Management

- **`bootstrap-apply.yml`**: Applies bootstrap to clusters (automatic on push or manual trigger)
- **`bootstrap-sync.yml`**: Periodic sync of bootstrap applications

See [`_bootstraps/CI_CD.md`](../../_bootstraps/CI_CD.md) for detailed documentation.

## Usage

### Apply Bootstrap

**Automatic**: Triggers on push to `main` branch when `_bootstraps/**` changes.

**Manual**: Can also be triggered manually via workflow dispatch:

```bash
gh workflow run bootstrap-apply.yml \
  -f cluster=docker-desktop \
  -f dry_run=false
```

### Sync Bootstrap

Runs automatically every 6 hours. To run manually:

```bash
gh workflow run bootstrap-sync.yml
```

## Configuration

### Self-Hosted Runners

All workflows are configured to run on self-hosted runners with tags: `self-hosted` and `local`.

**Setup Requirements**:
- Runner must have `kubectl` installed (or will be installed via action)
- Runner must have `helm` installed (or will be installed via action)
- Runner must have access to the target Kubernetes cluster

**Runner Setup**:
```bash
# Install GitHub Actions runner
# See: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners
```

### Required Secrets

Configure in **Settings** → **Secrets and variables** → **Actions**:

- `KUBECONFIG_DATA`: Base64 encoded kubeconfig (for apply workflow)
- `CLUSTER_CONTEXT`: Kubernetes context name (optional)

### Environment Protection

Configure in **Settings** → **Environments**:

- Add required reviewers for production deployments
- Restrict deployment branches to `main` only

