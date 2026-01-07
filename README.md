# GitOps Repository Template

A production-ready GitOps implementation using **ArgoCD** for managing Kubernetes clusters with automated deployments and infrastructure as code.

> **Template Repository**: After forking, follow the [Customization Guide](./docs/CUSTOMIZATION.md) to configure it for your organization.

## Quick Start

1. **Fork this repository** to your GitHub organization
2. **Clone your fork**: `git clone https://github.com/YOUR_ORG/YOUR_REPO.git`
3. **Follow [CUSTOMIZATION.md](./docs/CUSTOMIZATION.md)** to configure repository URLs, image registries, and Helm repositories
4. **Run setup**: `make local`

## Core Components

- **ApplicationSets** (`argocd/appset/`): Automated application discovery and deployment
- **Projects** (`argocd/projects/`): Environment isolation (dev/prod)
- **RBAC** (`argocd/rbac/`): Role-based access control
- **Notifications** (`argocd/notification/`): Slack/Teams integration
- **Infrastructure** (`infrastructure/`): Monitoring, databases, secrets
- **Apps** (`apps/`): Application configurations by environment

## Repository Structure

```
gitops/
├── _bootstraps/          # Bootstrap configuration
├── argocd/               # ArgoCD configuration
│   ├── appset/          # ApplicationSet definitions
│   ├── projects/        # Project definitions
│   ├── rbac/            # RBAC configuration
│   └── notification/    # Notification system
├── apps/                 # Application configurations
│   ├── development/     # Dev applications
│   └── production/       # Prod applications
├── docs/                 # Documentation
│   ├── CUSTOMIZATION.md # Customization guide
│   └── TEMPLATE_CONFIG.md # Template configuration reference
└── infrastructure/       # Infrastructure components
```

## Getting Started

### Prerequisites

- Docker Desktop with Kubernetes enabled (for local) or EKS cluster (for production)
- Helm (v3.x)
- kubectl configured for target cluster context

### Initialization Strategy

This GitOps setup follows a **platform-first** initialization strategy:

1. **Platform Cluster** (`cluster.type: platform`)
   - Hosts ArgoCD control plane
   - Runs infrastructure components (monitoring, logging, secrets management)
   - Must be initialized before application clusters

2. **Application Clusters** (`cluster.type: application`)
   - Run business applications
   - Separated by environment (`kubernetes.io/environment`)
   - Bootstrap components deploy here (when labeled)
   - Registered after platform cluster is ready

### Setup Options

#### Option 1: Local Setup (Makefile)

**Step 1: Initialize Platform Cluster**

```bash
# Complete platform cluster setup
make local

# Or run stages individually
make pre_check      # Check prerequisites
make argocd-install # Install ArgoCD on platform cluster
make init           # Apply bootstrap config (projects, RBAC, ApplicationSets)
```

**Step 2: Configure Platform Cluster Labels**

After ArgoCD is installed, label the platform cluster:

```bash
# Get the cluster secret name (usually 'in-cluster' for local)
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=cluster

# Add platform cluster labels
kubectl label secret <cluster-secret-name> -n argocd \
  cluster.type=platform \
```

**Step 3: Register Application Clusters** (After platform is ready)

```bash
# Create cluster secret for application cluster
# See argocd/external-clusters/README.md for details
kubectl apply -f argocd/external-clusters/<application-cluster>.yaml

# Label the cluster secret to schedule applications from apps/ directory
# For development environment (apps/development/*/*)
kubectl label secret <cluster-secret-name> -n argocd \
  cluster.type=application \
  kubernetes.io/environment=development

# For production environment (apps/production/*/*/*)
kubectl label secret <cluster-secret-name> -n argocd \
  cluster.type=application \
  kubernetes.io/environment=production
```

**Step 4: Enable Bootstrap Components on Application Clusters** (Optional)

Bootstrap components (Prometheus, core infrastructure, Vault agent injector) only deploy to application clusters with the appropriate labels:

```bash
# Enable Prometheus bootstrap
kubectl label secret <cluster-secret-name> -n argocd \
  cluster.bootstrap.prometheus="true"

# Enable core infrastructure bootstrap (gateway, monitoring)
kubectl label secret <cluster-secret-name> -n argocd \
  cluster.bootstrap.core="true"

# Enable Vault agent injector bootstrap
kubectl label secret <cluster-secret-name> -n argocd \
  cluster.bootstrap.vault-agent-injector="true"
```

**Step 5: Verify Bootstrap Applications**

```bash
# Check bootstrap ApplicationSets are syncing
kubectl get applicationsets -n argocd

# Verify bootstrap components are deploying to application clusters
kubectl get applications -n argocd | grep bootstrap
```

**Important Labels for Application Clusters**:
- `cluster.type: application` - Required for apps-dev, apps-prod, and bootstrap ApplicationSets
- `kubernetes.io/environment: development` - Schedules apps from `apps/development/` directory
- `kubernetes.io/environment: production` - Schedules apps from `apps/production/` directory
- `cluster.bootstrap.prometheus: "true"` - Enables Prometheus bootstrap on this cluster
- `cluster.bootstrap.core: "true"` - Enables core infrastructure bootstrap on this cluster
- `cluster.bootstrap.vault-agent-injector: "true"` - Enables Vault agent injector bootstrap on this cluster

**Note**: The `kubernetes.io/environment` label determines which ApplicationSet (`apps-dev` or `apps-prod`) will deploy applications to the cluster. Applications from `apps/development/` are deployed to clusters labeled `development`, and applications from `apps/production/` are deployed to clusters labeled `production`.


#### Option 2: GitHub Actions (Automated)

The repository includes automated GitHub Actions workflows for bootstrap management:

**Automatic Setup** (on push to main):
```bash
# 1. Configure self-hosted runner with tags: self-hosted, local
# 2. Push changes to _bootstraps/ directory
git add _bootstraps/
git commit -m "chore: bootstrap configuration"
git push origin main
# GitHub Actions will automatically apply bootstrap
```

**Workflow Features**:
- Validates configuration before applying
- Installs/upgrades ArgoCD automatically
- Applies root applications
- Verifies bootstrap completion
- Supports dry-run mode for testing

See [Bootstrap CI/CD](./_bootstraps/CI_CD.md) and [Workflows README](./.github/workflows/README.md) for detailed documentation.

### Post-Setup Steps

After running `make local`, complete the setup:

1. **Access ArgoCD UI**:
   ```bash
   kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```
   - URL: https://localhost:8080
   - Username: `admin`
   - **Note**: If `argocd-initial-admin-secret` doesn't exist, the password may have been changed. Check `argocd-secret` for the current password hash.

2. **Configure Image Updater SSH Secret** (Optional):
   ```bash
   kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
   ```

3. **Label Platform Cluster** (Required for bootstrap):
   - In ArgoCD UI: **Settings** → **Clusters** → Select platform cluster
   - Add labels:
     - `cluster.type: platform`

## Core Features

- **Platform-first initialization**: Platform clusters initialized before application clusters
- **Multi-cluster support**: Separate platform and application clusters
- **Multi-environment** (dev/prod) with separate configurations
- **Auto image updates** with ArgoCD Image Updater
- **Automated discovery** via ApplicationSets
- **RBAC** with role-based permissions
- **Notifications** for application lifecycle events
- **Infrastructure as Code** for monitoring, databases, secrets

## Documentation

- **[CUSTOMIZATION.md](./docs/CUSTOMIZATION.md)** - Step-by-step customization guide
- **[TEMPLATE_CONFIG.md](./docs/TEMPLATE_CONFIG.md)** - Quick reference for all customizable values
- **[Bootstrap CI/CD](./_bootstraps/README.md)** - Automated CI/CD for bootstrap management
- **[External Clusters](./argocd/external-clusters/README.md)** - Platform and application cluster registration
- **[ApplicationSets](./argocd/appset/README.md)** - ApplicationSet documentation
- **[Projects](./argocd/projects/README.md)** - Project configuration
- **[RBAC](./argocd/rbac/README.md)** - RBAC setup
- **[Notifications](./argocd/notification/README.md)** - Notification system
- **[Infrastructure](./infrastructure/README.md)** - Infrastructure components

## Customization Checklist

After forking, update:
- [ ] Repository URLs (`github.com/huytz/gitops` → your repo)
- [ ] Image registries (`ghcr.io/huytz` → your registry)
- [ ] Helm chart repositories
- [ ] RBAC roles and permissions
- [ ] Notification channels

See [CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) for detailed instructions.
