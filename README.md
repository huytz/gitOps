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
│   │   ├── apps.yml              # Application applications
│   │   ├── cluster-bootstrap.yml # Cluster bootstrap applications
│   │   └── infrastructure.yml    # Infrastructure applications
│   └── projects/                  # ArgoCD project definitions
│       ├── apps.yml              # Apps project
│       └── infrastructure.yml    # Infrastructure project
├── apps/                         # Application configurations
│   └── in-cluster/              # In-cluster applications
│       └── default/             # Default namespace
│           └── guestbook-ui/    # Guestbook UI application
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

- **Apps ApplicationSet** (`argocd/appset/apps.yml`): Manages application deployments
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

