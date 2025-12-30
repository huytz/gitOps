# RBAC Configuration

Role-Based Access Control (RBAC) defines permissions and access policies for ArgoCD users and groups.

## Core Roles

### `admin.yml`
Admin role with full access:
- ✅ Pod exec and logs access
- ✅ Full application, project, repository access
- ✅ Cluster and account management

### `developer.yml`
Developer role with read-only access:
- ✅ View applications in `apps-dev` and `apps-prod`
- ✅ View pod logs
- ❌ No create, update, delete, or sync permissions

### `image-updater.yml`
Image Updater service account:
- ✅ Application read and update access
- ✅ Secure Git write-back permissions

## Key Features

- ✅ **Role-Based Access**: Custom roles with specific permissions
- ✅ **Project Isolation**: Per-project access control
- ✅ **Group Integration**: LDAP, OIDC, SAML support
- ✅ **Least Privilege**: Minimal required permissions

## Usage

```bash
# List roles
kubectl get argocdroles -n argocd

# List role bindings
kubectl get argocdrolebindings -n argocd
```

## Reference

- [ArgoCD RBAC](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [RBAC Operator](https://argocd-rbac-operator.readthedocs.io/)
