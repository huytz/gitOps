# ArgoCD Projects Configuration

This directory contains ArgoCD project definitions that organize applications into logical groups with specific permissions and policies.

## Overview

ArgoCD projects provide:
- **Application Organization**: Logical grouping of applications
- **Access Control**: RBAC policies and permissions
- **Resource Management**: Source and destination restrictions
- **Notification Configuration**: Project-level notification subscriptions

## Project Structure

### Development Projects

#### `apps-dev.yml`
Development applications project with:
- **Namespace**: `argocd`
- **Source Repositories**: GitHub repositories for development apps
- **Destinations**: Development clusters and namespaces
- **Permissions**: Development team access
- **Notifications**: Development channel subscriptions

**Key Features**:
- Allows all source repositories for flexibility
- Restricts to development namespaces (`development/*`)
- Enables automatic sync for rapid development
- Configures development-specific notifications

#### `apps-prod.yml`
Production applications project with:
- **Namespace**: `argocd`
- **Source Repositories**: GitHub repositories for production apps
- **Destinations**: Production clusters and namespaces
- **Permissions**: Production team access
- **Notifications**: Production channel subscriptions

**Key Features**:
- Restricted source repositories for security
- Production namespace restrictions (`production/*`)
- Manual sync approval for production safety
- Production-specific notification channels

### Infrastructure Projects

#### `infrastructure.yml`
Infrastructure components project with:
- **Namespace**: `argocd`
- **Source Repositories**: Infrastructure and monitoring repositories
- **Destinations**: Infrastructure namespaces
- **Permissions**: Infrastructure team access
- **Notifications**: Infrastructure monitoring channels

**Key Features**:
- Infrastructure-specific source repositories
- Infrastructure namespace access (`infrastructure/*`)
- Automated sync for infrastructure components
- Infrastructure monitoring notifications

## Configuration Examples

### Development Project Configuration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: apps-dev
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.slack: dev-alerts
spec:
  description: Development applications
  sourceRepos:
  - '*'
  destinations:
  - namespace: development/*
    server: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
  roles:
  - name: developer
    description: Development team access
    policies:
    - p, proj:apps-dev:developer, applications, get, apps-dev/*, allow
    - p, proj:apps-dev:developer, applications, sync, apps-dev/*, allow
    groups:
    - developers
```

### Production Project Configuration
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: apps-prod
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.slack: prod-alerts
    notifications.argoproj.io/subscribe.slack: oncall-team
spec:
  description: Production applications
  sourceRepos:
  - https://github.com/huytz/gitops.git
  destinations:
  - namespace: production/*
    server: '*'
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
  roles:
  - name: operator
    description: Production operator access
    policies:
    - p, proj:apps-prod:operator, applications, get, apps-prod/*, allow
    - p, proj:apps-prod:operator, applications, sync, apps-prod/*, allow
    groups:
    - operators
```

## Best Practices

### Security
1. **Restrict Source Repositories**: Limit to trusted repositories in production
2. **Namespace Isolation**: Use separate namespaces for different environments
3. **RBAC Policies**: Implement least-privilege access principles
4. **Manual Sync**: Require manual approval for production deployments

### Organization
1. **Logical Grouping**: Group applications by environment and purpose
2. **Clear Naming**: Use descriptive project names
3. **Documentation**: Include descriptions for each project
4. **Notifications**: Configure appropriate notification channels

### Access Control
1. **Role-Based Access**: Define roles with specific permissions
2. **Group Integration**: Integrate with external identity providers
3. **Audit Trail**: Enable logging for access tracking
4. **Regular Review**: Periodically review and update permissions

## Usage

### Creating New Projects
1. Define project requirements (environments, teams, permissions)
2. Create project YAML file in this directory
3. Apply configuration via ArgoCD
4. Configure notification subscriptions
5. Assign applications to the project

### Managing Permissions
```bash
# List all projects
kubectl get appprojects -n argocd

# Get project details
kubectl get appproject apps-dev -n argocd -o yaml

# Update project configuration
kubectl apply -f apps-dev.yml
```

### Notification Configuration
Add notification subscriptions to project metadata:
```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.slack: channel-name
    notifications.argoproj.io/subscribe.email: email@example.com
```

## Reference

- [ArgoCD Projects Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/)
- [RBAC Configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [Project Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/#project-policies)
