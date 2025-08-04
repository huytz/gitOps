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
      - .spec.volumeClaimTemplates[].*
```

This prevents OutOfSync status caused by Kubernetes auto-generated fields in StatefulSets.

## 🛠️ Development Workflow

### Adding New Applications

1. **Create Directory Structure**:
   ```bash
   mkdir -p apps/<cluster>/<namespace>/<app-name>/
   ```

2. **Add Configuration**:
   ```bash
   # Create values.yaml
   cat > apps/<cluster>/<namespace>/<app-name>/values.yaml << EOF
   applicationName: <app-name>
   replicaCount: 1
   containerImage:
     repository: your-registry/your-image
     tag: latest
   EOF
   ```

3. **Commit and Deploy**:
   ```bash
   git add apps/<cluster>/<namespace>/<app-name>/
   git commit -m "Add <app-name> application"
   git push
   ```

### Adding New Infrastructure Components

1. **Create Directory Structure**:
   ```bash
   mkdir -p infrastructure/clusters/<cluster>/<component-type>/<component-name>/
   ```

2. **Add Helm Chart Configuration**:
   ```bash
   # Create charts.yaml
   cat > infrastructure/clusters/<cluster>/<component-type>/<component-name>/charts.yaml << EOF
   repoURL: https://prometheus-community.github.io/helm-charts
   chart: prometheus-blackbox-exporter
   targetRevision: 11.1.1
   EOF
   ```

3. **Add Values Configuration**:
   ```bash
   # Create values.yaml
   cat > infrastructure/clusters/<cluster>/<component-type>/<component-name>/values.yaml << EOF
   # Your Helm values here
   EOF
   ```

### Modifying Existing Components

1. **Edit Configuration**:
   ```bash
   # Edit the values.yaml file
   vim apps/<cluster>/<namespace>/<app-name>/values.yaml
   ```

2. **Commit and Deploy**:
   ```bash
   git add .
   git commit -m "Update <component-name> configuration"
   git push
   ```

3. **Monitor Deployment**:
   ```bash
   argocd app sync <app-name>
   argocd app get <app-name>
   ```

## 🔍 Monitoring and Troubleshooting

### ArgoCD UI
Access the ArgoCD UI to monitor application health and sync status:
```bash
# Port forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Application Health Status

- **Healthy** ✅: Application is synced and running
- **Degraded** ⚠️: Application has issues but is still running
- **Failed** ❌: Application has failed to deploy
- **Progressing** 🔄: Application is currently syncing
- **Suspended** ⏸️: Application sync is suspended

### Common Issues and Solutions

#### 1. Sync Failures
**Symptoms**: Application stuck in "Failed" or "Degraded" state
**Solutions**:
```bash
# Check application logs
argocd app logs <app-name>

# Check Kubernetes events
kubectl get events --sort-by='.lastTimestamp'

# Force sync
argocd app sync <app-name> --force
```

#### 2. Image Pull Errors
**Symptoms**: Pods in "ImagePullBackOff" state
**Solutions**:
```bash
# Check image pull secrets
kubectl get secrets -n <namespace>

# Verify image repository
kubectl describe pod <pod-name> -n <namespace>
```

#### 3. Resource Constraints
**Symptoms**: Pods in "Pending" state
**Solutions**:
```bash
# Check node resources
kubectl describe nodes

# Check pod resource requests
kubectl describe pod <pod-name> -n <namespace>
```

#### 4. ApplicationSet Issues
**Symptoms**: Applications not being created automatically
**Solutions**:
```bash
# Check ApplicationSet status
kubectl get applicationsets -n argocd

# Check ApplicationSet logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-applicationset-controller
```

#### 5. Vault Cluster Issues
**Symptoms**: Vault pods not ready or cluster not forming
**Solutions**:
```bash
# Check Vault pod status
kubectl get pods -n secret-manager -l app.kubernetes.io/name=vault

# Check Vault cluster status
kubectl exec vault-0 -n secret-manager -- vault status

# Unseal Vault nodes (if needed)
kubectl exec vault-0 -n secret-manager -- vault operator unseal <key1>
kubectl exec vault-0 -n secret-manager -- vault operator unseal <key2>
kubectl exec vault-0 -n secret-manager -- vault operator unseal <key3>
```

#### 6. StatefulSet OutOfSync Issues
**Symptoms**: StatefulSets showing OutOfSync despite working correctly
**Solutions**:
- This is handled automatically by the `ignoreDifferences` configuration
- The Infrastructure ApplicationSet ignores volumeClaimTemplates status fields
- Applications may show OutOfSync but function correctly

### Debugging Commands

```bash
# List all applications
argocd app list

# Get detailed application info
argocd app get <app-name>

# Check application resources
argocd app resources <app-name>

# View application manifest
argocd app manifest <app-name>

# Check sync status
argocd app sync-status <app-name>

# Check Vault cluster status
kubectl exec vault-0 -n secret-manager -- vault status

# Check PVC status for StatefulSets
kubectl get pvc -n <namespace>
```

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ApplicationSet Documentation](https://argocd-applicationset.readthedocs.io/)
- [Helm Charts Documentation](https://helm.sh/docs/)
- [Kong Ingress Documentation](https://docs.konghq.com/kubernetes-ingress-controller/)
- [Prometheus Operator Documentation](https://prometheus-operator.dev/)
- [HashiCorp Vault Documentation](https://www.vaultproject.io/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes following the development workflow
4. Test the deployment thoroughly
5. Submit a pull request with detailed description

### Code Review Guidelines

- Ensure all applications are properly labeled
- Verify Helm chart versions are pinned
- Check that resource limits are appropriate
- Confirm security best practices are followed
- Test StatefulSet configurations thoroughly

## 📄 License

This project is licensed under the MIT License.

## 🔄 Version History

- **v1.0.0**: Initial GitOps setup with ArgoCD and ApplicationSets
- **v1.1.0**: Added monitoring stack (Prometheus, Blackbox Exporter)
- **v1.2.0**: Added Kong ingress controller and Redis database
- **v1.3.0**: Enhanced documentation and troubleshooting guides
- **v1.4.0**: Added HashiCorp Vault with HA Raft cluster and PVC storage
- **v1.5.0**: Optimized ApplicationSet sync policies for StatefulSets
