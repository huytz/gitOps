# GitOps Repository

This repository contains the GitOps configuration for managing Kubernetes clusters using ArgoCD. It follows a declarative approach where all infrastructure and application configurations are version-controlled and automatically deployed.

## 🏗️ Repository Structure

```
gitops/
├── _bootstraps/                    # Root ArgoCD applications
│   ├── root-argocd-appset.yml     # Bootstraps ApplicationSet controller
│   └── root-projects.yml          # Bootstraps ArgoCD projects
├── argocd/                        # ArgoCD configuration
│   ├── appset/                    # ApplicationSet definitions
│   │   ├── apps.yml              # Production application applications
│   │   ├── apps-dev.yml          # Development application applications
│   │   ├── cluster-bootstrap.yml # Cluster bootstrap applications
│   │   └── infrastructure.yml    # Infrastructure applications
│   └── projects/                  # ArgoCD project definitions
│       ├── apps.yml              # Apps project
│       └── infrastructure.yml    # Infrastructure project
├── apps/                         # Production application configurations
│   └── in-cluster/              # In-cluster applications
│       └── default/             # Default namespace
│           └── guestbook-ui/    # Guestbook UI application
├── apps-dev/                     # Development application configurations
│   └── in-cluster/              # In-cluster applications
│       └── development/         # Development namespace
│           └── webapp/          # Web application
└── infrastructure/               # Infrastructure components
    ├── cluster-bootstrap/        # Cluster bootstrap components
    │   ├── gateway/             # Gateway components
    │   │   └── kong-ingress/   # Kong ingress controller
    │   └── monitoring/          # Monitoring stack
    │       ├── blackbox-exporter/ # Blackbox exporter
    │       └── prometheus/      # Prometheus monitoring
    └── clusters/                # Cluster-specific infrastructure
        └── in-cluster/          # In-cluster resources
            ├── databases/        # Database components
            │   └── redis/       # Redis database
            └── secret-manager/   # Secret management
                └── vault/        # HashiCorp Vault
```

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster with ArgoCD installed
- ArgoCD CLI tools (`argocd`)
- `kubectl` configured for your cluster
- Access to the target cluster

### Bootstrap Process

1. **Deploy Root Applications**: The bootstrap process starts with deploying the root applications that manage the rest of the GitOps pipeline.

   ```bash
   # Apply root applications
   kubectl apply -f _bootstraps/root-argocd-appset.yml
   kubectl apply -f _bootstraps/root-projects.yml
   ```

2. **ApplicationSet Controller**: The `root-argocd-appset.yml` deploys the ApplicationSet controller which enables the use of ApplicationSets for dynamic application generation.

3. **Project Management**: The `root-projects.yml` deploys ArgoCD projects that organize applications into logical groups.

4. **Verify Deployment**: Check that the root applications are healthy:

   ```bash
   argocd app list
   argocd app get root-argocd-appset
   argocd app get root-projects
   ```

## 🚀 Adding New Clusters

### Overview

This GitOps repository supports multi-cluster deployments through a structured approach that automatically bootstraps new clusters with essential infrastructure components.

### Cluster Bootstrap Process

#### 1. **Cluster Registration**

First, register your new cluster with ArgoCD:

```bash
# Create cluster secret for ArgoCD
kubectl create secret generic <cluster-name> \
  --from-literal=name=<cluster-name> \
  --from-literal=server=https://<cluster-api-server> \
  --from-literal=config=<kubeconfig-base64> \
  -n argocd

# Label the cluster for bootstrap
kubectl label secret <cluster-name> \
  argocd.argoproj.io/secret-type="cluster" \
  kubernetes.io/environment="prod" \
  cluster.bootstrap.prometheus="true" \
  cluster.bootstrap.vault-agent-injector="true" \
  cluster.bootstrap.prometheus="true"
  -n argocd
```

#### 2. **Bootstrap Applications**

The following applications are automatically deployed to new clusters:

##### **Monitoring Stack**
- **Prometheus**: Remote write to mimir with tenant name base on cluster name.
- **Blackbox Exporter**: External monitoring

##### **Gateway Components**
- **Kong Ingress Controller**: API gateway and load balancing
- **SSL termination and rate limiting**

##### **Secret Management**
- **Vault Agent Injector**: Automatic secret injection base on cluster name.

## 📋 Components

### Application Management

Applications are managed through ApplicationSets that automatically discover and deploy applications based on the directory structure:

- **Apps ApplicationSet** (`argocd/appset/apps.yml`): Manages production application deployments
- **Apps-Dev ApplicationSet** (`argocd/appset/apps-dev.yml`): Manages development application deployments with automatic image updates
- **Infrastructure ApplicationSet** (`argocd/appset/infrastructure.yml`): Manages infrastructure components with StatefulSet sync optimization
- **Cluster Bootstrap ApplicationSet** (`argocd/appset/cluster-bootstrap.yml`): Manages cluster-level components

### Infrastructure Components

#### Gateway
- **Kong Ingress Controller**: Provides ingress management and API gateway functionality
  - Location: `infrastructure/cluster-bootstrap/gateway/kong-ingress/`
  - Features: Load balancing, SSL termination, rate limiting

#### Monitoring
- **Prometheus Stack**: Complete monitoring solution with Prometheus, Grafana, and AlertManager
  - Location: `infrastructure/cluster-bootstrap/monitoring/prometheus/`
  - Features: Metrics collection, alerting, visualization
- **Blackbox Exporter**: External monitoring for HTTP endpoints
  - Location: `infrastructure/cluster-bootstrap/monitoring/blackbox-exporter/`
  - Features: Uptime monitoring, response time tracking

#### Secret Management
- **HashiCorp Vault**: Enterprise-grade secret management with HA Raft cluster
  - Location: `infrastructure/clusters/in-cluster/secret-manager/vault/`
  - Features: 
    - 3-node HA cluster with Raft storage
    - Persistent Volume Claims (PVC) instead of Consul
    - TLS disabled for internal communication
    - Kubernetes-native deployment
    - Auto-unsealing support (configurable)

#### Databases
- **Redis**: In-memory data structure store
  - Location: `infrastructure/clusters/in-cluster/databases/redis/`
  - Features: Caching, session storage, real-time analytics

### Applications

#### Guestbook UI
A sample application demonstrating the GitOps workflow:
- **Location**: `apps/in-cluster/default/guestbook-ui/`
- **Chart**: Uses `k8s-service` Helm chart from Gruntwork
- **Configuration**: Customized through `values.yaml`
- **Purpose**: Demonstrates application deployment patterns

#### Development Applications (Apps-Dev)

The `apps-dev` ApplicationSet manages development applications with automatic image updates:

##### **Web Application**
- **Location**: `apps-dev/in-cluster/development/webapp/`
- **Chart**: Uses `k8s-service` Helm chart from Gruntwork
- **Configuration**: Customized through `values.yaml`
- **Features**: 
  - Automatic image updates via ArgoCD Image Updater
  - Development environment isolation
  - Git-based configuration management

##### **ApplicationSet Configuration**
The `apps-dev` ApplicationSet (`argocd/appset/apps-dev.yml`) includes:

```yaml
# Image updater annotations for automatic updates
argocd-image-updater.argoproj.io/image-list: app=ghcr.io/huytz/{{.path.basename}}
argocd-image-updater.argoproj.io/app.allow-tags: regexp:^main-[0-9a-f]{7}$
argocd-image-updater.argoproj.io/app.update-strategy: alphabetical
argocd-image-updater.argoproj.io/app.platform: linux/amd64
argocd-image-updater.argoproj.io/app.force-update: "true"

# Helm parameters for image updates
argocd-image-updater.argoproj.io/app.helm.image-name: containerImage.repository
argocd-image-updater.argoproj.io/app.helm.image-tag: containerImage.tag

# Git write-back configuration
argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/git-creds
argocd-image-updater.argoproj.io/git-branch: main
argocd-image-updater.argoproj.io/git-repository: git@github.com:huytz/gitops.git
argocd-image-updater.argoproj.io/write-back-target: "helmvalues:/{{.path.path}}/values.yaml"
```

**Features:**
- ✅ **Automatic Image Updates**: Monitors container registries for new image tags
- ✅ **Tag Filtering**: Only updates to `main-*` tags matching 7-character hex commit hashes
- ✅ **Alphabetical Strategy**: Updates to the latest commit hash when sorted alphabetically
- ✅ **Git Write-Back**: Automatically commits changes to the Git repository
- ✅ **Platform Compatibility**: Configured for `linux/amd64` platform
- ✅ **Development Isolation**: Separate namespace and configuration from production

## 🔧 Configuration

### Application Configuration

Applications are configured using Helm values files located in their respective directories. For example:

```yaml
# apps/in-cluster/default/guestbook-ui/values.yaml
applicationName: guestbook-ui
replicaCount: 1
containerImage:
  repository: gcr.io/google-samples/gb-frontend
  tag: v5
service:
  type: ClusterIP
  port: 80
ingress:
  enabled: true
  className: kong
```

### Infrastructure Configuration

Infrastructure components use standard Helm charts with custom values:

- **Kong Ingress**: Uses Kong Helm chart with custom configuration
  - SSL configuration
  - Plugin management
  - Resource limits
- **Prometheus**: Uses kube-prometheus-stack with monitoring configuration
  - Retention policies
  - Alert rules
  - Grafana dashboards
- **Vault**: Uses HashiCorp Vault Helm chart with HA configuration
  - Raft storage with PVC
  - 3-node cluster for high availability
  - TLS disabled for internal communication
  - Kubernetes service discovery
- **Redis**: Uses Bitnami Redis chart with persistence configuration
  - Persistence settings
  - Security configurations
  - Resource limits

### ArgoCD Image Updater Configuration

The ArgoCD Image Updater automatically updates container images in applications based on configured policies:

#### **Configuration Location**
- **Values File**: `infrastructure/clusters/in-cluster/argocd/argocd-image-updater/values.yaml`
- **ConfigMap**: `argocd-image-updater-config` in the `argocd` namespace

#### **Key Configuration**

```yaml
# infrastructure/clusters/in-cluster/argocd/argocd-image-updater/values.yaml
config:
  applicationsAPIKind: "kubernetes"
  argocd:
    serverAddress: "argocd-server.argocd.svc.cluster.local:80"
    insecure: true
    plaintext: true
    token: "<argocd-api-token>"
  
  # Git commit configuration
  gitCommitUser: "huytz"
  gitCommitTemplate: "feat: update {{.AppName}} to {{.Image}}:{{.Tag}} ({{.PrevTag}} -> {{.Tag}})"
  
  # Platform preferences for image selection
  platforms: "linux/amd64"
  
  # Logging
  logLevel: "debug"
```

#### **Features**
- ✅ **Automatic Image Monitoring**: Polls container registries for new image tags
- ✅ **Git Write-Back**: Commits changes directly to Git repositories
- ✅ **Platform Compatibility**: Handles multi-platform image manifests
- ✅ **Tag Filtering**: Supports regex patterns for tag selection
- ✅ **Update Strategies**: Multiple strategies (alphabetical, newest-build, semver)
- ✅ **Helm Integration**: Updates Helm chart values automatically
- ✅ **Kustomize Support**: Updates Kustomize-based applications
- ✅ **RBAC Integration**: Respects ArgoCD RBAC policies

#### **Update Strategies**
- **`alphabetical`**: Sorts tags alphabetically and picks the last one
- **`newest-build`**: Uses image creation timestamps (requires metadata)
- **`semver`**: Semantic versioning-based updates
- **`digest`**: Updates to the most recent digest of a mutable tag

#### **Platform Compatibility**
The image updater is configured to handle platform mismatches:
- **Issue**: Updater running on `darwin/arm64` trying to read `linux` image metadata
- **Solution**: Platform annotation `linux/amd64` in application configurations
- **Fallback**: `alphabetical` strategy when metadata reading fails

### Vault Configuration

The Vault cluster is configured for high availability with Raft storage:

```yaml
# infrastructure/clusters/in-cluster/secret-manager/vault/values.yaml
server:
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        cluster_name = "vault-integrated-storage"
        listener "tcp" {
          address = "[::]:8200"
          cluster_address = "[::]:8201"
          tls_disable = 1
        }
        storage "raft" {
          path = "/vault/data"
          node_id = "vault-${HOSTNAME##*-}"
          retry_join {
            leader_api_addr = "http://vault-0.vault-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://vault-1.vault-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://vault-2.vault-internal:8200"
          }
        }
```

## 🏷️ Labeling Strategy

Applications are automatically labeled based on:
- `appset`: The ApplicationSet that manages them
- `environment`: The target environment (e.g., `prod`, `staging`)
- `cluster`: The target cluster name
- `namespace`: The Kubernetes namespace
- `app`: The application name

## 🔄 Sync Policy

All applications use automated sync policies with:
- **Prune**: Automatically removes resources when they're no longer in Git
- **Self-Heal**: Automatically corrects drift from the desired state
- **CreateNamespace**: Automatically creates namespaces if they don't exist
- **Sync Options**: 
  - `ServerSideApply=true`: Uses server-side apply for better conflict resolution
  - `CreateNamespace=true`: Creates namespaces automatically

### StatefulSet Sync Optimization

The Infrastructure ApplicationSet includes optimized sync settings for StatefulSets:

```yaml
# argocd/appset/infrastructure.yml
ignoreDifferences:
  - group: apps
    kind: StatefulSet
    jqPathExpressions:
      - .spec.volumeClaimTemplates[].apiVersion
      - .spec.volumeClaimTemplates[].kind
```

This prevents OutOfSync status caused by Kubernetes auto-generated fields in StatefulSets by ignoring specific volumeClaimTemplates fields that are managed by Kubernetes.

### Vault Agent Injector

The Vault Agent Injector is a Kubernetes webhook that automatically injects Vault agents into pods:

```yaml
# infrastructure/cluster-bootstrap/vault-agent-injector/values.yaml
webhook:
  failurePolicy: Ignore
  matchPolicy: Exact
  timeoutSeconds: 30
  namespaceSelector: {}
  objectSelector: |
    matchExpressions:
    - key: app.kubernetes.io/name
      operator: NotIn
      values:
      - vault-agent-injector
```

**Features:**
- ✅ **Automatic Injection**: Injects Vault agents into pods with `vault.hashicorp.com/agent-inject: "true"`
- ✅ **Self-Exclusion**: Prevents infinite loops by excluding the injector itself
- ✅ **Failure Tolerance**: Pods start even if Vault injection fails
- ✅ **Timeout Protection**: 30-second timeout prevents hanging
- ✅ **Namespace Agnostic**: Works across all namespaces

## 🔧 Troubleshooting

### ArgoCD Image Updater Issues

#### **Platform Mismatch Errors**
```
Manifest list did not contain any usable reference. Platforms requested: (darwin/arm64), platforms included: (linux/amd64,linux/arm64)
```

**Solution**: Add platform annotation to application:
```yaml
argocd-image-updater.argoproj.io/app.platform: linux/amd64
```

#### **Template Errors**
```
can't evaluate field ImageName in type argocd.commitMessageTemplate
```

**Solution**: Use correct template variables:
```yaml
gitCommitTemplate: "feat: update {{.AppName}} to {{.Image}}:{{.Tag}} ({{.PrevTag}} -> {{.Tag}})"
```

#### **Image Not Found**
```
Image 'image-name' seems not to be live in this application, skipping
```

**Solution**: Verify image name in annotation matches actual image in values.yaml:
- Annotation: `app=ghcr.io/huytz/webapp`
- Values: `repository: ghcr.io/huytz/webapp`

### Best Practices

#### **Image Update Configuration**
1. **Use Specific Tag Patterns**: `regexp:^main-[0-9a-f]{7}$` for commit-based tags
2. **Choose Appropriate Strategy**: `alphabetical` for commit hashes, `newest-build` for timestamps
3. **Enable Force Updates**: `force-update: "true"` for development environments
4. **Configure Platform**: Specify platform when using `newest-build` strategy

#### **Git Write-Back**
1. **Use SSH Authentication**: Configure SSH keys for secure Git access
2. **Set Commit User**: Configure `gitCommitUser` for proper attribution
3. **Custom Commit Messages**: Use templates for consistent commit messages
4. **Branch Protection**: Ensure target branch allows automated commits

#### **Monitoring and Logging**
1. **Enable Debug Logging**: `logLevel: "debug"` for troubleshooting
2. **Monitor Update Cycles**: Check logs for successful updates
3. **Track Metrics**: Enable metrics for monitoring update frequency
4. **Health Checks**: Monitor image updater pod health

