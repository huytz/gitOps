# RBAC Configuration

Role-Based Access Control (RBAC) defines permissions and access policies for ArgoCD users and groups.

## Table of Contents

- [Core Roles](#core-roles)
- [Key Features](#key-features)
- [Usage](#usage)
- [Examples](#examples)
- [Reference](#reference)

## Core Roles

### `admin.yml`
Admin role with full access:
- Pod exec and logs access
- Full application, project, repository access
- Cluster and account management

### `developer.yml`
Developer role with read-only access:
- View applications in `apps-dev` and `apps-prod`
- View pod logs
- No create, update, delete, or sync permissions

## Key Features

- **Role-Based Access**: Custom roles with specific permissions
- **Project Isolation**: Per-project access control
- **Group Integration**: LDAP, OIDC, SAML support
- **Least Privilege**: Minimal required permissions

## Usage

```bash
# List roles
kubectl get argocdroles -n argocd

# List role bindings
kubectl get argocdrolebindings -n argocd
```

## Examples

### Creating a Custom Role

```yaml
apiVersion: rbac-operator.argoproj-labs.io/v1alpha1
kind: ArgoCDRole
metadata:
  name: custom-role
  namespace: argocd
spec:
  rules:
    # Allow viewing and syncing applications in apps-dev project
    - resource: "applications"
      verbs: ["get", "sync"]
      objects: ["apps-dev/*"]
```

### Binding a Role to a User

```yaml
apiVersion: rbac-operator.argoproj-labs.io/v1alpha1
kind: ArgoCDRoleBinding
metadata:
  name: custom-binding
  namespace: argocd
spec:
  subjects:
    - kind: "local"
      name: "developer"
  argocdRoleRef:
    name: "custom-role"
```

## Reference

- [ArgoCD RBAC](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [RBAC Operator](https://argocd-rbac-operator.readthedocs.io/)
