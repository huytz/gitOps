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
            └── databases/       # Database components
                └── redis/       # Redis database
```

## 🚀 Getting Started

### Prerequisites

- Kubernetes cluster with ArgoCD installed
- ArgoCD CLI tools
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

## 📋 Components

### Application Management

Applications are managed through ApplicationSets that automatically discover and deploy applications based on the directory structure:

- **Apps ApplicationSet** (`argocd/appset/apps.yml`): Manages application deployments
- **Infrastructure ApplicationSet** (`argocd/appset/infrastructure.yml`): Manages infrastructure components

### Infrastructure Components

#### Gateway
- **Kong Ingress Controller**: Provides ingress management and API gateway functionality

#### Monitoring
- **Prometheus Stack**: Complete monitoring solution with Prometheus, Grafana, and AlertManager
- **Blackbox Exporter**: External monitoring for HTTP endpoints

#### Databases
- **Redis**: In-memory data structure store

### Applications

#### Guestbook UI
A sample application demonstrating the GitOps workflow:
- **Location**: `apps/in-cluster/default/guestbook-ui/`
- **Chart**: Uses `k8s-service` Helm chart from Gruntwork
- **Configuration**: Customized through `values.yaml`

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
```

### Infrastructure Configuration

Infrastructure components use standard Helm charts with custom values:

- **Kong Ingress**: Uses Kong Helm chart with custom configuration
- **Prometheus**: Uses kube-prometheus-stack with monitoring configuration
- **Redis**: Uses Bitnami Redis chart with persistence configuration

## 🏷️ Labeling Strategy

Applications are automatically labeled based on:
- `appset`: The ApplicationSet that manages them
- `environment`: The target environment (e.g., `prod`)
- `cluster`: The target cluster name

## 🔄 Sync Policy

All applications use automated sync policies with:
- **Prune**: Automatically removes resources when they're no longer in Git
- **Self-Heal**: Automatically corrects drift from the desired state
- **CreateNamespace**: Automatically creates namespaces if they don't exist

## 🛠️ Development Workflow

1. **Add New Application**:
   - Create a new directory under `apps/` following the pattern: `apps/<cluster>/<namespace>/<app-name>/`
   - Add a `values.yaml` file with your application configuration
   - Commit and push to trigger automatic deployment

2. **Add New Infrastructure Component**:
   - Create a new directory under `infrastructure/clusters/<cluster>/<namespace>/<component-name>/`
   - Add a `values.yaml` file with your component configuration
   - Update the ApplicationSet template if using a new Helm chart

3. **Modify Existing Components**:
   - Edit the `values.yaml` file in the component's directory
   - Commit and push to trigger automatic updates

## 🔍 Monitoring and Troubleshooting

### ArgoCD UI
Access the ArgoCD UI to monitor application health and sync status.

### Application Health
- **Healthy**: Application is synced and running
- **Degraded**: Application has issues but is still running
- **Failed**: Application has failed to deploy

### Common Issues
1. **Sync Failures**: Check application logs in ArgoCD UI
2. **Image Pull Errors**: Verify image repository and credentials
3. **Resource Constraints**: Check cluster resource availability

## 📚 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ApplicationSet Documentation](https://argocd-applicationset.readthedocs.io/)
- [Helm Charts Documentation](https://helm.sh/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
