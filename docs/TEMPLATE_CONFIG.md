# Template Configuration Reference

This file serves as a quick reference for all customizable values in this template. Use this as a checklist when customizing the repository.

## 🔧 Configuration Values

### Repository Configuration

| Variable | Current Value | Description | Files to Update |
|----------|--------------|-------------|-----------------|
| `GIT_REPO_URL` | `https://github.com/huytz/gitops.git` | Your GitOps repository URL (HTTPS) | All ApplicationSet files, bootstrap files |
| `GIT_REPO_SSH` | `git@github.com:huytz/gitops.git` | Your GitOps repository URL (SSH) | ApplicationSet files with image updater |
| `GIT_BRANCH` | `main` | Default Git branch name | ApplicationSet files |

### Container Registry Configuration

| Variable | Current Value | Description | Files to Update |
|----------|--------------|-------------|-----------------|
| `IMAGE_REGISTRY` | `ghcr.io/huytz` | Container image registry prefix | ApplicationSet files, app values files |
| `IMAGE_TAG_PATTERN_DEV` | `^develop-[0-9a-f]{7}$` | Development image tag regex pattern | `apps-dev.yml` |
| `IMAGE_TAG_PATTERN_PROD` | `^main-[0-9a-f]{7}$` | Production image tag regex pattern | `apps-prod.yml` |

### Helm Configuration

| Variable | Current Value | Description | Files to Update |
|----------|--------------|-------------|-----------------|
| `HELM_REPO_URL` | `https://huytz.github.io/helm-kubernetes-services/` | Helm chart repository URL | `apps-dev.yml`, `apps-prod.yml` |
| `HELM_CHART_NAME` | `k8s-service` | Helm chart name | `apps-dev.yml`, `apps-prod.yml` |
| `HELM_CHART_VERSION_DEV` | `0.0.*` | Development chart version | `apps-dev.yml` |
| `HELM_CHART_VERSION_PROD` | `0.0.2` | Production chart version | `apps-prod.yml` |

### Cluster Configuration

| Variable | Current Value | Description | Files to Update |
|----------|--------------|-------------|-----------------|
| `CLUSTER_NAME` | `in-cluster` | Default cluster name | Directory structure, ApplicationSets |
| `ENV_LABEL_DEV` | `development` | Development environment label | ApplicationSet selectors |
| `ENV_LABEL_PROD` | `production` | Production environment label | ApplicationSet selectors |

## 📝 Quick Find & Replace

Use these commands to quickly find all occurrences:

```bash
# Find all repository URLs
grep -r "github.com/huytz/gitops" .

# Find all image registries
grep -r "ghcr.io/huytz" .

# Find all Helm repositories
grep -r "huytz.github.io" .

# Find all Git branch references
grep -r "git-branch: main" .
```

## 🔄 Bulk Replacement Script

Create a script to automate replacements:

```bash
#!/bin/bash
# customize-template.sh

# Set your values
ORG_NAME="your-org"
REPO_NAME="your-repo"
IMAGE_REGISTRY="ghcr.io/${ORG_NAME}"
HELM_REPO="https://${ORG_NAME}.github.io/your-helm-repo"

# Replace repository URLs
find . -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sed -i '' \
  "s|github.com/huytz/gitops|github.com/${ORG_NAME}/${REPO_NAME}|g" {} +

# Replace image registries
find . -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sed -i '' \
  "s|ghcr.io/huytz|${IMAGE_REGISTRY}|g" {} +

# Replace Helm repositories
find . -type f \( -name "*.yml" -o -name "*.yaml" \) -exec sed -i '' \
  "s|https://huytz.github.io/helm-kubernetes-services/|${HELM_REPO}|g" {} +

echo "✅ Customization complete!"
```

## 📋 File-by-File Checklist

### ApplicationSet Files

- [ ] `argocd/appset/apps-dev.yml`
  - [ ] Line 14: `repoURL`
  - [ ] Line 28: `image-list` (registry)
  - [ ] Line 29: `allow-tags` (tag pattern)
  - [ ] Line 39: `git-branch`
  - [ ] Line 40: `git-repository` (SSH URL)
  - [ ] Line 51: Helm `repoURL`
  - [ ] Line 58: `repoURL` (values source)

- [ ] `argocd/appset/apps-prod.yml`
  - [ ] Line 14: `repoURL`
  - [ ] Line 28: `image-list` (registry)
  - [ ] Line 29: `allow-tags` (tag pattern)
  - [ ] Line 39: `git-branch`
  - [ ] Line 40: `git-repository` (SSH URL)
  - [ ] Line 51: Helm `repoURL`
  - [ ] Line 58: `repoURL` (values source)

- [ ] `argocd/appset/infrastructure.yml`
  - [ ] Line 16: `repoURL`
  - [ ] Line 34: `repoURL`

- [ ] `argocd/appset/manifest.yaml`
  - [ ] Line 16: `repoURL`
  - [ ] Line 34: `repoURL`

- [ ] `argocd/appset/01-bootstrap-prometheus.yml`
  - [ ] Line 17: `repoURL`
  - [ ] Line 41: `repoURL`

- [ ] `argocd/appset/02-bootstrap-core.yml`
  - [ ] Line 17: `repoURL`
  - [ ] Line 41: `repoURL`

- [ ] `argocd/appset/03-bootstrap-vault-agent-injector.yml`
  - [ ] Line 17: `repoURL`
  - [ ] Line 41: `repoURL`

### Bootstrap Files

- [ ] `_bootstraps/root/root-argocd-appset.yml`
  - [ ] Line 9: `repoURL`

- [ ] `_bootstraps/root/root-argocd-rbac.yml`
  - [ ] Line 9: `repoURL`

- [ ] `_bootstraps/root/root-argocd-notification.yml`
  - [ ] Line 9: `repoURL`

- [ ] `_bootstraps/root/root-projects.yml`
  - [ ] Line 9: `repoURL`

### Application Values

- [ ] `apps/development/default/webapp/values.yaml`
  - [ ] Line 4: `repository` (image registry)

- [ ] `apps/production/in-cluster/default/webapp/values.yaml`
  - [ ] Line 4: `repository` (image registry)

### RBAC Files

- [ ] `argocd/rbac/admin.yml`
  - [ ] Update user/group names

- [ ] `argocd/rbac/developer.yml`
  - [ ] Update user/group names

## 🎯 Environment-Specific Notes

### Development Environment
- Uses more permissive image tag patterns
- Allows automatic updates
- Typically uses `develop-*` or `dev-*` tags

### Production Environment
- Uses stricter image tag patterns
- May require manual approval
- Typically uses `main-*`, `release-*`, or semantic versions

## 📚 Related Documentation

- [Customization Guide](./CUSTOMIZATION.md) - Detailed customization instructions
- [README.md](../README.md) - Main repository documentation

