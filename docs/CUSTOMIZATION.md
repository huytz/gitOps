# Customization Guide

This guide will help you customize this GitOps template repository for your organization after forking.

## 📋 Prerequisites

Before starting customization, ensure you have:
- Forked this repository to your GitHub organization/account
- Access to your container image registry (e.g., GitHub Container Registry, Docker Hub, etc.)
- Your Helm chart repository URL (if using custom charts)
- SSH key for Git write-back operations (for ArgoCD Image Updater)

## 🔧 Required Customizations

### 1. Repository URLs

Replace all occurrences of `github.com/huytz/gitops` with your repository URL.

#### Files to Update:

- `argocd/appset/apps-dev.yml`
- `argocd/appset/apps-prod.yml`
- `argocd/appset/infrastructure.yml`
- `argocd/appset/manifest.yaml`
- `argocd/appset/01-bootstrap-prometheus.yml`
- `argocd/appset/02-bootstrap-core.yml`
- `argocd/appset/03-bootstrap-vault-agent-injector.yml`
- `_bootstraps/root/root-argocd-appset.yml`
- `_bootstraps/root/root-argocd-rbac.yml`
- `_bootstraps/root/root-argocd-notification.yml`
- `_bootstraps/root/root-projects.yml`

#### Search and Replace:

```bash
# Find all occurrences
grep -r "github.com/huytz/gitops" .

# Replace with your repository (example)
find . -type f -name "*.yml" -o -name "*.yaml" | xargs sed -i '' 's|github.com/huytz/gitops|github.com/YOUR_ORG/YOUR_REPO|g'
```

**Important**: Update both HTTPS and SSH URLs:
- `https://github.com/huytz/gitops.git` → `https://github.com/YOUR_ORG/YOUR_REPO.git`
- `git@github.com:huytz/gitops.git` → `git@github.com:YOUR_ORG/YOUR_REPO.git`

### 2. Container Image Registry

Replace `ghcr.io/huytz` with your container image registry.

#### Files to Update:

- `argocd/appset/apps-dev.yml` (line 28)
- `argocd/appset/apps-prod.yml` (line 28)
- `apps/development/default/webapp/values.yaml`
- `apps/production/in-cluster/default/webapp/values.yaml`

#### Examples:

**GitHub Container Registry:**
```yaml
# Replace
argocd-image-updater.argoproj.io/image-list: app=ghcr.io/huytz/{{.path.basename}}

# With
argocd-image-updater.argoproj.io/image-list: app=ghcr.io/YOUR_ORG/{{.path.basename}}
```

**Docker Hub:**
```yaml
argocd-image-updater.argoproj.io/image-list: app=YOUR_DOCKERHUB_USER/{{.path.basename}}
```

**Private Registry:**
```yaml
argocd-image-updater.argoproj.io/image-list: app=registry.example.com/YOUR_ORG/{{.path.basename}}
```

### 3. Helm Chart Repository

If you're using a custom Helm chart repository, update the repository URL.

#### Files to Update:

- `argocd/appset/apps-dev.yml` (line 51)
- `argocd/appset/apps-prod.yml` (line 51)

#### Example:

```yaml
# Replace
- repoURL: https://huytz.github.io/helm-kubernetes-services/

# With your Helm repository
- repoURL: https://YOUR_ORG.github.io/YOUR_HELM_REPO/
```

**Note**: If you're using standard Helm charts from public repositories (e.g., Bitnami, official charts), you may not need to change this. Update only if you have custom Helm charts.

### 4. Git Branch Name

If your default branch is not `main`, update all references.

#### Files to Update:

- `argocd/appset/apps-dev.yml` (line 39)
- `argocd/appset/apps-prod.yml` (line 39)

#### Example:

```yaml
# Replace
argocd-image-updater.argoproj.io/git-branch: main

# With
argocd-image-updater.argoproj.io/git-branch: master  # or your branch name
```

### 5. Image Tag Patterns

Customize the image tag regex patterns to match your CI/CD workflow.

#### Development Environment (`apps-dev.yml`):

```yaml
# Current pattern: matches tags like develop-abc1234
argocd-image-updater.argoproj.io/app.allow-tags: regexp:^develop-[0-9a-f]{7}$

# Examples of other patterns:
# - Semantic versioning: regexp:^v?[0-9]+\.[0-9]+\.[0-9]+$
# - Branch-based: regexp:^develop-.*$
# - SHA-based: regexp:^[0-9a-f]{7,40}$
```

#### Production Environment (`apps-prod.yml`):

```yaml
# Current pattern: matches tags like main-abc1234
argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$

# Examples of other patterns:
# - Semantic versioning: regexp:^v?[0-9]+\.[0-9]+\.[0-9]+$
# - Release tags: regexp:^release-.*$
```

### 6. RBAC Configuration

Customize RBAC roles and permissions for your team.

#### Files to Review:

- `argocd/rbac/admin.yml`
- `argocd/rbac/developer.yml`
- `argocd/rbac/image-updater.yml`

#### Key Customizations:

1. **Update user/group names** in `argocd/rbac/admin.yml` and `argocd/rbac/developer.yml`
2. **Configure external identity providers** (LDAP, OIDC, SAML) if needed
3. **Adjust permissions** based on your security requirements

### 7. Notification Configuration

Configure Slack or other notification services.

#### Files to Review:

- `argocd/notification/services/slack.yaml`
- `argocd/notification/templates/*.yaml`

#### Setup Steps:

1. **Create Slack App** (if using Slack):
   - Go to https://api.slack.com/apps
   - Create a new app and get the bot token
   - Add the token as a Kubernetes secret:
     ```bash
     kubectl create secret generic argocd-notifications-secret \
       --from-literal=slack-token=xoxb-your-slack-bot-token \
       -n argocd
     ```

2. **Update Slack Channel Names**:
   - Update channel references in project annotations
   - Modify templates if needed for your organization's format

### 8. Cluster Names and Labels

Update cluster names and environment labels to match your infrastructure.

#### Files to Review:

- All ApplicationSet files in `argocd/appset/`

#### Common Customizations:

1. **Cluster Names**: Replace `in-cluster` with your cluster names
2. **Environment Labels**: Ensure `kubernetes.io/environment` labels match your setup
3. **Namespace Structure**: Adjust namespace paths if your structure differs

### 9. Application Values

Update example application values to match your applications.

#### Files to Update:

- `apps/development/default/webapp/values.yaml`
- `apps/production/in-cluster/default/webapp/values.yaml`

#### Example:

```yaml
# Update image repository
containerImage:
  repository: ghcr.io/YOUR_ORG/webapp  # Change to your image
  tag: "develop-abc1234"  # Update tag pattern

# Update resource limits
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🔍 Verification Checklist

After customization, verify:

- [ ] All repository URLs point to your fork
- [ ] Container image registries are updated
- [ ] Helm chart repositories are configured
- [ ] Git branch names match your repository
- [ ] Image tag patterns match your CI/CD workflow
- [ ] RBAC roles are configured for your team
- [ ] Notification services are set up (if using)
- [ ] Cluster names and labels match your infrastructure
- [ ] Example application values are updated

## 🚀 Post-Customization Steps

1. **Commit your changes**:
   ```bash
   git add .
   git commit -m "chore: customize template for organization"
   git push origin main
   ```

2. **Set up ArgoCD Image Updater SSH Secret**:
   ```bash
   kubectl -n argocd create secret generic git-creds \
     --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
   ```

3. **Configure cluster labels** in ArgoCD UI:
   - Go to Settings → Clusters
   - Add appropriate labels (e.g., `kubernetes.io/environment: production`)

4. **Test the setup**:
   ```bash
   make local  # For local development
   ```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)
- [ArgoCD Notifications](https://argocd-notifications.readthedocs.io/)
- [ApplicationSet Documentation](https://argocd-applicationset.readthedocs.io/)

## 📝 Notes

- This template uses `main` as the default branch. If your repository uses `master`, update all references.
- The template assumes GitHub Container Registry (`ghcr.io`). Adjust for other registries.
- Default Helm chart repository points to a custom repository. Update if using standard charts.
- All paths and structures can be customized to match your organization's conventions.

