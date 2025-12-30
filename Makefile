.PHONY: pre_check argocd-install init local

# Check if required tools are installed and kubectl context is set to docker-desktop
pre_check:
	@echo "🔍 Checking prerequisites for Helm operations..."
	@echo "Checking Helm installation..."
	@which helm > /dev/null 2>&1 || (echo "❌ Helm is not installed. Please install Helm first." && exit 1)
	@echo "✅ Helm is installed: $(shell helm version)"
	@echo ""
	@echo "Checking kubectl installation..."
	@which kubectl > /dev/null 2>&1 || (echo "❌ kubectl is not installed. Please install kubectl first." && exit 1)
	@echo "✅ kubectl is installed: $(shell kubectl version --client)"
	@echo ""
	@echo "Checking Docker Desktop kubectl context..."
	@kubectl config current-context > /dev/null 2>&1 || (echo "❌ No kubectl context is set. Please set a context first." && exit 1)
	@if [ "$$(kubectl config current-context)" != "docker-desktop" ]; then \
		echo "❌ Current kubectl context is '$$(kubectl config current-context)', but 'docker-desktop' is required."; \
		echo "   Available contexts:"; \
		kubectl config get-contexts -o name | sed 's/^/   - /'; \
		echo ""; \
		echo "   To switch to docker-desktop context, run:"; \
		echo "   kubectl config use-context docker-desktop"; \
		exit 1; \
	fi
	@echo "✅ kubectl context is set to docker-desktop"
	@echo ""
	@echo "🎉 All prerequisites are met! Ready for Helm operations."

# Install ArgoCD using Helm with custom values
argocd-install: pre_check
	@echo "🚀 Installing ArgoCD..."
	@echo "Adding Argo Helm repository..."
	@helm repo add argo https://argoproj.github.io/argo-helm
	@helm repo update
	@echo ""
	@echo "Creating argocd namespace..."
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@echo ""
	@echo "Installing ArgoCD with custom configuration..."
	@helm upgrade --install argo-cd argo/argo-cd \
		--version 8.2.5 \
		--namespace argocd \
		--values _bootstraps/argocd.yml \
		--wait \
		--timeout 10m
	@echo ""
	@echo "✅ ArgoCD installation completed!"
	@echo ""
	@echo "🔗 To access ArgoCD UI, run:"
	@echo "   kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443"
	@echo ""
	@echo "🔑 To get the admin password, run:"
	@echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"

# Initialize GitOps bootstrap configuration
init: pre_check
	@echo "🔧 Initializing GitOps bootstrap configuration..."
	@echo "Applying root bootstrap manifests..."
	@kubectl apply -f _bootstraps/root/
	@echo ""
	@echo "✅ Bootstrap configuration applied successfully!"
	@echo ""
	@echo "📋 Applied manifests from _bootstraps/root/:"
	@ls -la _bootstraps/root/

# Complete local setup - runs all stages in sequence
local: pre_check argocd-install init
	@echo ""
	@echo "🎉 Complete local GitOps setup finished!"
	@echo ""
	@echo "📋 Summary of what was completed:"
	@echo "   ✅ Prerequisites checked (Helm, kubectl, docker-desktop context)"
	@echo "   ✅ ArgoCD installed with HA configuration"
	@echo "   ✅ Bootstrap manifests applied"
	@echo ""
	@echo "🔗 Next steps:"
	@echo "   1. Access ArgoCD UI: kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443"
	@echo "   2. Get admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
	@echo "   3. Login to ArgoCD UI at https://localhost:8080 (username: admin)"
	@echo ""
	@echo "📖 For complete post-setup steps, see:"
	@echo "   https://github.com/huytz/gitOps?tab=readme-ov-file#post-setup-steps"
	@echo ""
	@echo "🚀 Your GitOps environment is ready!"
