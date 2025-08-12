# GitOps Repository

A comprehensive GitOps implementation using **ArgoCD** for managing Kubernetes clusters with automated deployments, continuous monitoring, and infrastructure as code practices.

## 🎯 Overview

A **production-ready GitOps workflow** using ArgoCD for automated Kubernetes deployments with:

- 🚀 **Multi-environment applications** (dev/prod)
- 🏗️ **Infrastructure as Code** (monitoring, databases, secrets)
- 🔄 **Auto image updates** with ArgoCD Image Updater
- 🔐 **Security** (RBAC, Vault, secure Git workflows)
- 📊 **Observability** (Prometheus, Grafana)

### ✨ Key Features

- **🔧 One-command setup**: `make local` for complete local environment
- **🔄 Declarative management**: GitOps workflow with ArgoCD
- **📦 Multi-environment**: Separate dev/prod configurations
- **🖼️ Auto deployments**: Continuous image updates
- **🔐 Security-first**: RBAC and secrets management
- **🔔 Real-time notifications**: Slack integration for application lifecycle events

## 🏗️ Repository Structure

```
gitops/
├── _bootstraps/                   # Bootstrap configuration
│   ├── argocd.yml                # ArgoCD Helm values
│   └── root/                     # Root ArgoCD applications
│       ├── root-argocd-appset.yml
│       ├── root-argocd-rbac.yml
│       └── root-projects.yml
├── argocd/                       # ArgoCD configuration
│   ├── appset/                   # ApplicationSet definitions
│   │   ├── 01-bootstrap-prometheus.yml
│   │   ├── 02-bootstrap-core.yml
│   │   ├── 03-bootstrap-vault-agent-injector.yml
│   │   ├── apps-dev.yml
│   │   ├── apps-prod.yml
│   │   ├── infrastructure.yml
│   │   └── README.md             # ApplicationSet documentation
│   ├── notification/             # Notification system configuration
│   │   ├── templates/            # Message templates
│   │   ├── triggers/             # Event triggers
│   │   ├── services/             # External integrations (Slack)
│   │   └── README.md             # Notification documentation
│   ├── projects/                 # ArgoCD project definitions
│   │   ├── apps-dev.yml
│   │   ├── apps-prod.yml
│   │   ├── infrastructure.yml
│   │   └── README.md             # Projects documentation
│   └── rbac/                     # RBAC configuration
│       ├── image-updater.yml
│       └── README.md             # RBAC documentation
├── apps/                         # Application configurations
│   ├── development/              # Development applications
│   │   └── default/
│   │       └── webapp/
│   │           └── values.yaml
│   └── production/               # Production applications
│       └── in-cluster/
│           └── default/
│               └── webapp/
│                   └── values.yaml
├── infrastructure/               # Infrastructure components
│   ├── cluster-bootstrap/        # Cluster-level bootstrap
│   │   ├── core/                 # Core infrastructure
│   │   │   ├── gateway/          # Gateway components
│   │   │   │   └── kong-ingress/
│   │   │   └── monitor/          # Monitoring components
│   │   │       └── blackbox-exporter/
│   │   ├── prometheus/           # Prometheus monitoring
│   │   └── vault-agent-injector/ # Vault integration
│   ├── clusters/                 # Cluster-specific configurations
│   │   └── in-cluster/           # In-cluster resources
│   │       ├── argocd/           # ArgoCD components
│   │       │   ├── argocd-image-updater/
│   │       │   └── argocd-rbac-operator/
│   │       ├── databases/        # Database components
│   │       │   └── redis/
│   │       ├── monitoring/       # Monitoring stack
│   │       │   └── prometheus/
│   │       └── secret-manager/   # Secret management
│   │           └── vault/
│   └── README.md                 # Infrastructure documentation
├── Makefile                      # Automation scripts
└── README.md                     # This file
```

## 🚀 Getting Started

### Prerequisites

- **Docker Desktop** with Kubernetes enabled
- **Helm** (v3.x) installed
- **kubectl** configured for docker-desktop context
- **Git** for repository access

### Local Development Setup

The repository includes a comprehensive Makefile for easy local development setup.

#### **Quick Start (Recommended)**

Run the complete setup in one command:

```bash
make local
```

This will:
1. ✅ Check all prerequisites (Helm, kubectl, docker-desktop context)
2. ✅ Install ArgoCD with HA configuration
3. ✅ Apply bootstrap manifests
4. 📋 Provide next steps for accessing ArgoCD UI

#### **Manual Setup Stages**

If you prefer to run stages individually:

```bash
# 1. Check prerequisites only
make pre_check

# 2. Install ArgoCD only
make argocd-install

# 3. Apply bootstrap configuration only
make init
```

#### **Post-Setup Steps**

After running `make local`, access your GitOps environment:

1. **Start port-forwarding**:
   ```bash
   kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
   ```

2. **Get admin password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Access ArgoCD UI**:
   - URL: https://localhost:8080
   - Username: `admin`
   - Password: (from step 2)

4. **Configure ArgoCD Image Updater SSH Secret** (for automatic image updates):
   ```bash
   kubectl -n argocd create secret generic git-creds --from-file=sshPrivateKey="$HOME/.ssh/id_rsa"
   ```
   This enables the ArgoCD Image Updater to commit changes back to the Git repository.

5. **Add Production Environment Label** (for automated infrastructure deployment):
   - In ArgoCD UI, go to **Settings** → **Clusters**
   - Select your cluster (usually `in-cluster` or `docker-desktop`)
   - Add label: `kubernetes.io/environment: production`
   - This enables automatic deployment of infrastructure components from `infrastructure/clusters/in-cluster`


#### **Verify Deployment**

```bash
# List all ArgoCD applications
argocd app list

# Check ArgoCD server status
kubectl get pods -n argocd
```

## 📋 ApplicationSets

Applications are managed through ApplicationSets that automatically discover and deploy applications based on the directory structure.

### Overview

The ApplicationSet system provides:
- **🔍 Automated Discovery**: Automatically find applications based on directory structure
- **🌐 Multi-Cluster Deployment**: Deploy to multiple clusters with matrix generators
- **⚙️ Dynamic Configuration**: Generate applications from Git repositories
- **📝 Consistent Patterns**: Standardized application naming and configuration

### ApplicationSet Types

- **Apps-Prod ApplicationSet** (`argocd/appset/apps-prod.yml`): Production applications
- **Apps-Dev ApplicationSet** (`argocd/appset/apps-dev.yml`): Development applications with automatic image updates
- **Infrastructure ApplicationSet** (`argocd/appset/infrastructure.yml`): Infrastructure components
- **Bootstrap ApplicationSets** (`argocd/appset/01-*.yml`): Cluster-level bootstrap components

### Key Features

- ✅ **Multi-Environment Support**: Separate configurations for dev and prod
- ✅ **Automatic Image Updates**: Development environments with ArgoCD Image Updater
- ✅ **Git Write-Back**: Automatic commits for image updates
- ✅ **Dynamic Chart Discovery**: Infrastructure components using `charts.yaml` files
- ✅ **StatefulSet Optimization**: Special handling for persistent storage components

### Documentation

For detailed configuration, examples, and best practices, see:
**[📖 ApplicationSet Documentation](./argocd/appset/README.md)**

## 🏗️ Projects & RBAC

### Projects

ArgoCD projects organize applications into logical groups with specific permissions and policies:

- **Apps-Dev Project** (`argocd/projects/apps-dev.yml`): Development applications with flexible access
- **Apps-Prod Project** (`argocd/projects/apps-prod.yml`): Production applications with restricted access
- **Infrastructure Project** (`argocd/projects/infrastructure.yml`): Infrastructure components with specialized permissions

### RBAC Configuration

Role-Based Access Control provides secure access management:

- **Image Updater RBAC** (`argocd/rbac/image-updater.yml`): Permissions for ArgoCD Image Updater
- **Custom Roles**: Developer, operator, and read-only roles
- **External Integration**: LDAP, OIDC, and SAML support

### Key Features

- ✅ **Environment Isolation**: Separate projects for dev and prod
- ✅ **Access Control**: Role-based permissions and policies
- ✅ **Security**: Least-privilege access principles
- ✅ **Integration**: External identity provider support

### Documentation

For detailed configuration and best practices, see:
- **[📖 Projects Documentation](./argocd/projects/README.md)**
- **[📖 RBAC Documentation](./argocd/rbac/README.md)**

## 🔔 Notifications System

The GitOps repository includes a comprehensive notification system using **ArgoCD Notifications** that provides real-time alerts for application lifecycle events, health status changes, and sync operations.

### Overview

The notification system is configured using Kustomize and includes:
- **📧 Templates**: Message formats for different notification types (deployment, sync, health)
- **🔔 Triggers**: Conditions that activate notifications (app created, sync failed, health degraded)
- **🔗 Services**: Integration with external platforms (Slack, Teams, Email)
- **⚙️ Default Triggers**: Pre-configured trigger combinations for common events

### Key Features

- **🚨 Real-time Alerts**: Instant notifications for critical events
- **📱 Slack Integration**: Direct integration with Slack channels
- **🎯 Granular Control**: Project and application-level notification configuration
- **🔄 Lifecycle Events**: Complete coverage of application lifecycle events
- **⚡ Automated Setup**: Managed via ArgoCD ApplicationSet

### Quick Setup

1. **Configure Slack Integration**:
   ```bash
   # Create Slack app and get bot token from https://api.slack.com/apps
   kubectl create secret generic argocd-notifications-secret \
     --from-literal=slack-token=xoxb-your-slack-bot-token \
     -n argocd
   ```

2. **Subscribe Projects to Channels**:
   ```yaml
   # In your project configuration
   metadata:
     annotations:
       notifications.argoproj.io/subscribe.slack: my-channel
   ```

3. **Verify Configuration**:
   ```bash
   # Check notification configuration
   kubectl get configmap argocd-notifications-cm -n argocd -o yaml
   
   # Check notification controller logs
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller
   ```

### Notification Types

- **📋 Application Lifecycle**: Created, deleted, deployed events
- **💚 Health Status**: Degraded, healthy state changes
- **🔄 Sync Operations**: Running, succeeded, failed, unknown status
- **🚨 Critical Alerts**: Sync failures, health degradation

### Documentation

For detailed configuration, customization, and troubleshooting information, see:
**[📖 ArgoCD Notifications Documentation](./argocd/notification/README.md)**

The notification system is automatically deployed via the `argocd-notification` ApplicationSet located in `_bootstraps/root/root-argocd-notification.yml`.

## 🏗️ Infrastructure & Image Updates

### Overview

The infrastructure layer provides comprehensive automation and management capabilities:

- **🔧 ArgoCD Image Updater**: Automatic container image updates with Git write-back
- **🔄 Sync Policies**: Automated application synchronization with drift correction
- **🏗️ Infrastructure Components**: Monitoring, databases, and secret management
- **⚙️ Configuration Management**: Helm charts and values for all components

### Key Features

- ✅ **Automatic Image Updates**: Monitors container registries and updates application images
- ✅ **Git Write-Back**: Automatically commits changes to Git repositories
- ✅ **Multi-Platform Support**: Handles different image architectures
- ✅ **Tag Filtering**: Supports regex patterns for selective updates
- ✅ **SSH Authentication**: Secure Git access for automatic commits
- ✅ **StatefulSet Optimization**: Special handling for persistent storage components

### Infrastructure Components

- **Monitoring Stack**: Prometheus, Grafana, Blackbox Exporter
- **Database Components**: Redis, PostgreSQL (if needed)
- **Secret Management**: Vault and Vault Agent Injector
- **Gateway Components**: Kong Ingress for API management

### Documentation

For detailed configuration, examples, and best practices, see:
**[📖 Infrastructure Documentation](./infrastructure/README.md)**

This includes:
- Complete ArgoCD Image Updater configuration
- Automatic image update workflow examples
- Sync policy configuration and optimization
- Infrastructure component management
- SSH key setup and troubleshooting

