# ArgoCD Projects Configuration

Projects organize applications into logical groups with specific permissions and policies.

## Table of Contents

- [Core Projects](#core-projects)
- [Key Features](#key-features)
- [Usage](#usage)
- [Examples](#examples)
- [Reference](#reference)

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

- **Environment Isolation**: Separate projects for dev/prod
- **Access Control**: RBAC policies per project
- **Notifications**: Project-level Slack/Teams subscriptions
- **Resource Management**: Source and destination restrictions

## Usage

```bash
# List projects
kubectl get appprojects -n argocd

# Get project details
kubectl get appproject apps-dev -n argocd -o yaml
```

## Examples

### Creating a New Project

Projects are defined in YAML files. Example structure:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: My custom project
  sourceRepos:
    - '*'
  destinations:
    - namespace: '*'
      server: '*'
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
```

### Project Sync Policies

Projects can define sync policies:

- **Automated**: Auto-sync with prune and self-heal
- **Manual**: Requires manual approval for syncs
- **Sync Windows**: Time-based sync restrictions

## Reference

- [ArgoCD Projects](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/)
- [Project Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/#project-policies)
