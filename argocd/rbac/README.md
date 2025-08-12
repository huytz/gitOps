# ArgoCD RBAC Configuration

This directory contains Role-Based Access Control (RBAC) configurations for ArgoCD, defining permissions and access policies for different users and groups.

## Overview

RBAC in ArgoCD provides:
- **User Access Control**: Define who can access what resources
- **Project Permissions**: Control access to specific projects and applications
- **Role Definitions**: Create custom roles with specific permissions
- **Group Integration**: Integrate with external identity providers

## RBAC Structure

### Image Updater RBAC

#### `image-updater.yml`
RBAC configuration for ArgoCD Image Updater:
- **ServiceAccount**: `argocd-image-updater`
- **Role**: `argocd-image-updater`
- **Permissions**: Application read and update access
- **Namespace**: `argocd`

**Key Features**:
- ✅ Application read access for image discovery
- ✅ Application update access for image updates
- ✅ Project-specific permissions
- ✅ Secure Git write-back permissions

## Configuration Examples

### Image Updater RBAC Configuration
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-image-updater
  namespace: argocd
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argocd-image-updater
  namespace: argocd
rules:
  - apiGroups:
      - argoproj.io
    resources:
      - applications
    verbs:
      - get
      - list
      - watch
      - patch
      - update
  - apiGroups:
      - argoproj.io
    resources:
      - appprojects
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: argocd-image-updater
  namespace: argocd
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: argocd-image-updater
subjects:
  - kind: ServiceAccount
    name: argocd-image-updater
    namespace: argocd
```

## RBAC Best Practices

### Security Principles
1. **Least Privilege**: Grant only necessary permissions
2. **Role Separation**: Separate roles for different functions
3. **Regular Review**: Periodically review and update permissions
4. **Audit Logging**: Enable audit trails for access tracking

### Permission Management
1. **Project-Based Access**: Use project-specific permissions
2. **Environment Isolation**: Separate permissions by environment
3. **Team-Based Roles**: Create roles aligned with team responsibilities
4. **Temporary Access**: Use temporary permissions for special tasks

### Integration Patterns
1. **External Identity**: Integrate with LDAP, OIDC, or SAML
2. **Group Mapping**: Map external groups to ArgoCD roles
3. **SSO Integration**: Use single sign-on for authentication
4. **Multi-Factor Authentication**: Enable MFA for sensitive operations

## Common RBAC Patterns

### Developer Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: argocd
rules:
  - apiGroups:
      - argoproj.io
    resources:
      - applications
    verbs:
      - get
      - list
      - watch
    resourceNames:
      - "apps-dev/*"
```

### Operator Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: operator
  namespace: argocd
rules:
  - apiGroups:
      - argoproj.io
    resources:
      - applications
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete
```

### Read-Only Role
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: read-only
  namespace: argocd
rules:
  - apiGroups:
      - argoproj.io
    resources:
      - applications
      - appprojects
      - repositories
    verbs:
      - get
      - list
      - watch
```

## Usage

### Creating New RBAC Configurations
1. Define the required permissions
2. Create ServiceAccount for the component
3. Define Role with appropriate permissions
4. Create RoleBinding to link ServiceAccount and Role
5. Apply the configuration

### Managing RBAC
```bash
# List all roles in ArgoCD namespace
kubectl get roles -n argocd

# Get role details
kubectl get role argocd-image-updater -n argocd -o yaml

# List role bindings
kubectl get rolebindings -n argocd

# Check permissions for a service account
kubectl auth can-i --as=system:serviceaccount:argocd:argocd-image-updater get applications -n argocd
```

### Testing Permissions
```bash
# Test specific permissions
kubectl auth can-i get applications --as=system:serviceaccount:argocd:argocd-image-updater -n argocd

# Test project-specific permissions
kubectl auth can-i update applications --as=system:serviceaccount:argocd:argocd-image-updater -n argocd

# Check all permissions for a user
kubectl auth can-i --list --as=system:serviceaccount:argocd:argocd-image-updater -n argocd
```

## Troubleshooting

### Common Issues
1. **Permission Denied**: Check role bindings and permissions
2. **Service Account Issues**: Verify ServiceAccount exists and is bound
3. **Namespace Problems**: Ensure permissions are in the correct namespace
4. **Resource Access**: Verify resource names and API groups

### Debugging Commands
```bash
# Check RBAC configuration
kubectl get roles,rolebindings,serviceaccounts -n argocd

# View detailed role information
kubectl describe role argocd-image-updater -n argocd

# Check role binding subjects
kubectl describe rolebinding argocd-image-updater -n argocd

# Test specific access
kubectl auth can-i --as=system:serviceaccount:argocd:argocd-image-updater get applications -n argocd
```

## Reference

- [ArgoCD RBAC Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [ArgoCD User Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/)
- [RBAC Best Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
