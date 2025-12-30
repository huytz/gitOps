# ArgoCD Projects Configuration

Projects organize applications into logical groups with specific permissions and policies.

## Core Projects

### `apps-dev.yml`
Development applications:
- **Destinations**: `development/*` namespaces
- **Sync Policy**: Automated with prune and self-heal
- **Source Repos**: All (`*`)

### `apps-prod.yml`
Production applications:
- **Destinations**: `production/*` namespaces
- **Sync Policy**: Manual approval required
- **Source Repos**: Restricted to GitOps repo

### `infrastructure.yml`
Infrastructure components:
- **Destinations**: `infrastructure/*` namespaces
- **Sync Policy**: Automated
- **Source Repos**: Infrastructure repositories

## Key Features

- ✅ **Environment Isolation**: Separate projects for dev/prod
- ✅ **Access Control**: RBAC policies per project
- ✅ **Notifications**: Project-level Slack/Teams subscriptions
- ✅ **Resource Management**: Source and destination restrictions

## Usage

```bash
# List projects
kubectl get appprojects -n argocd

# Get project details
kubectl get appproject apps-dev -n argocd -o yaml
```

## Reference

- [ArgoCD Projects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/)
- [Project Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/#project-policies)
