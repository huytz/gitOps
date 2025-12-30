# GitOps Repository Template

A production-ready GitOps implementation using **ArgoCD** for managing Kubernetes clusters with automated deployments and infrastructure as code.

> **📌 Template Repository**: After forking, follow the [Customization Guide](./docs/CUSTOMIZATION.md) to configure it for your organization.

## 🚀 Quick Start

1. **Fork this repository** to your GitHub organization
2. **Clone your fork**: `git clone https://github.com/YOUR_ORG/YOUR_REPO.git`
3. **Follow [CUSTOMIZATION.md](./docs/CUSTOMIZATION.md)** to configure repository URLs, image registries, and Helm repositories
4. **Run setup**: `make local`

## 🎯 Core Components

- **ApplicationSets** (`argocd/appset/`): Automated application discovery and deployment
- **Projects** (`argocd/projects/`): Environment isolation (dev/prod)
- **RBAC** (`argocd/rbac/`): Role-based access control
- **Notifications** (`argocd/notification/`): Slack/Teams integration
- **Infrastructure** (`infrastructure/`): Monitoring, databases, secrets
- **Apps** (`apps/`): Application configurations by environment

## 🏗️ Repository Structure

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

## 🚀 Getting Started

### Prerequisites

- Docker Desktop with Kubernetes enabled
- Helm (v3.x)
- kubectl configured for docker-desktop context

### Setup Options

#### Option 1: Local Setup (Makefile)

```bash
# Complete setup in one command
make local

# Or run stages individually
make pre_check      # Check prerequisites
make argocd-install # Install ArgoCD
make init           # Apply bootstrap config
```

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
- ✅ Validates configuration before applying
- ✅ Installs/upgrades ArgoCD automatically
- ✅ Applies root applications
- ✅ Verifies bootstrap completion
- ✅ Supports dry-run mode for testing

See [Bootstrap CI/CD](./_bootstraps/CI_CD.md) and [Workflows README](./.github/workflows/README.md) for detailed documentation.

### Post-Setup-steps

After running `make local`, complete the setup:

1. **Access ArgoCD UI**:
   ```bash
   kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```
   - URL: https://localhost:8080
   - Username: `admin`

2. **Configure Image Updater SSH Secret**: ( Optional )
   ```bash
   kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
   ```

3. **Label Cluster** (for automated infrastructure deployment):
   - In ArgoCD UI: **Settings** → **Clusters** → Add label `kubernetes.io/environment: production`

## 📋 Core Features

- ✅ **Multi-environment** (dev/prod) with separate configurations
- ✅ **Auto image updates** with ArgoCD Image Updater
- ✅ **Automated discovery** via ApplicationSets
- ✅ **RBAC** with role-based permissions
- ✅ **Notifications** for application lifecycle events
- ✅ **Infrastructure as Code** for monitoring, databases, secrets

## 📚 Documentation

- **[CUSTOMIZATION.md](./docs/CUSTOMIZATION.md)** - Step-by-step customization guide
- **[TEMPLATE_CONFIG.md](./docs/TEMPLATE_CONFIG.md)** - Quick reference for all customizable values
- **[Bootstrap CI/CD](./_bootstraps/CI_CD.md)** - Automated CI/CD for bootstrap management
- **[ApplicationSets](./argocd/appset/README.md)** - ApplicationSet documentation
- **[Projects](./argocd/projects/README.md)** - Project configuration
- **[RBAC](./argocd/rbac/README.md)** - RBAC setup
- **[Notifications](./argocd/notification/README.md)** - Notification system
- **[Infrastructure](./infrastructure/README.md)** - Infrastructure components

## 📝 Customization Checklist

After forking, update:
- [ ] Repository URLs (`github.com/huytz/gitops` → your repo)
- [ ] Image registries (`ghcr.io/huytz` → your registry)
- [ ] Helm chart repositories
- [ ] RBAC roles and permissions
- [ ] Notification channels

See [CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) for detailed instructions.
