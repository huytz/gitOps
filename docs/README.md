# GitOps ArgoCD Repository Documentation

This repository implements GitOps principles using ArgoCD to manage Kubernetes applications deployed via Helm charts from `charts.huytran.dev`.

## 📚 Documentation Structure

- **[Getting Started](./getting-started.md)** - Quick start guide
- **[Architecture](./architecture.md)** - Repository structure and design
- **[ArgoCD Projects](./argocd-projects.md)** - Project configuration and management
- **[Applications](./applications.md)** - Application deployment patterns
- **[ApplicationSets](./applicationsets.md)** - Multi-environment deployments
- **[Helm Charts](./helm-charts.md)** - Helm chart integration
- **[Environments](./environments.md)** - Environment-specific configurations
- **[Best Practices](./best-practices.md)** - GitOps and ArgoCD best practices
- **[Troubleshooting](./troubleshooting.md)** - Common issues and solutions

## 🏗️ Repository Structure

```
fleet-infra/
├── argocd/                          # ArgoCD configuration
│   ├── projects/                    # ArgoCD Projects
│   ├── applications/                # Individual Applications
│   └── applicationsets/             # Multi-environment ApplicationSets
├── apps/                            # Application components
├── infrastructure/                  # Infrastructure components
└── docs/                           # Documentation
```

## 🚀 Quick Start

1. **Setup ArgoCD**: Install ArgoCD in your cluster
2. **Configure Projects**: Apply ArgoCD project configurations
3. **Deploy Applications**: Use Applications or ApplicationSets
4. **Monitor**: Use ArgoCD UI to monitor deployments

## 📖 Key Concepts

- **GitOps**: Git as the single source of truth
- **ArgoCD**: Kubernetes-native continuous delivery
- **Helm Charts**: Package management for Kubernetes
- **ApplicationSets**: Multi-environment deployment automation

## 🔗 External Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [GitOps Principles](https://www.gitops.tech/) 