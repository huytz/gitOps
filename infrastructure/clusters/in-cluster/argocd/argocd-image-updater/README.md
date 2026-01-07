# Argo CD Image Updater - AWS CloudEvents Webhook Setup

Configure Argo CD Image Updater to receive webhooks from AWS EventBridge for ECR image push events across multiple AWS accounts.

## Table of Contents

- [Benefits of Enabling Webhook](#benefits-of-enabling-webhook)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Resources](#resources)

## Benefits of Enabling Webhook

When webhook is enabled, Argo CD Image Updater receives real-time notifications instead of polling:

- **Real-time updates**: Instant notifications when images are pushed (no polling delay)
- **Cost efficient**: Eliminates frequent API calls to container registries
- **Reduced latency**: Applications update immediately after image push
- **Multi-account support**: Single webhook endpoint receives events from multiple AWS accounts
- **Scalable**: Handles high-volume image pushes without performance degradation
- **Resource efficient**: Reduces CPU and network usage compared to polling

## Architecture

```
Account 1 (ECR) ──┐
                  │
Account 2 (ECR) ──┼──► EventBridge API Destination ──► Argo CD Webhook
                  │
Account 3 (ECR) ──┘
```

## Prerequisites

- **Argo CD Cluster**: Argo CD Image Updater installed, webhook endpoint accessible from AWS EventBridge
- **AWS Accounts**: ECR repositories, Terraform configured, permissions to create EventBridge rules

## Setup

### Step 1: Enable Webhook in Argo CD Image Updater

Configure webhook endpoint and generate a secret:

```yaml
# values.yaml
argocd-image-updater:
  config:
    webhook:
      enabled: true
      secret: "your-webhook-secret-here"  # Generate with: openssl rand -hex 32
      path: "/api/webhook"
```

**Note**: Ensure webhook URL is accessible from AWS EventBridge (public endpoint, LoadBalancer, or VPN/Direct Connect).

### Step 2: Configure AWS EventBridge (Per Account)

Deploy the [Terraform module](https://github.com/huytz/infrastructure/tree/main/modules/aws/argocd-image-updater) to each AWS account:

```hcl
# main.tf
module "argocd_image_updater_webhook" {
  source = "github.com/huytz/infrastructure//modules/aws/argocd-image-updater?ref=main"

  webhook_url    = "https://argocd.example.com/api/webhook"
  webhook_secret = "your-webhook-secret-here"
  aws_region     = "us-west-2"
  ecr_repository_filter = []  # Empty = all repositories
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

```hcl
# terraform.tfvars
aws_region = "us-west-2"
webhook_url = "https://argocd.example.com/api/webhook"
webhook_secret = "your-webhook-secret-from-step-1"
ecr_repository_filter = ["my-app", "another-app"]  # Optional
```

Apply:
```bash
terraform init && terraform plan && terraform apply
```

### Step 3: Configure Registries

Update `argocd-image-updater-config` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries: |
    - name: AWS ECR Account 1
      prefix: <account-1-id>.dkr.ecr.<region>.amazonaws.com
      api: ecr
      credentials: ext:/scripts/ecr-login.sh
      default: true
    - name: AWS ECR Account 2
      prefix: <account-2-id>.dkr.ecr.<region>.amazonaws.com
      api: ecr
      credentials: ext:/scripts/ecr-login.sh
      default: true
```

**Note**: Argo CD Image Updater automatically processes CloudEvents format from AWS EventBridge.

## Resources

- [Argo CD Image Updater Documentation](https://argocd-image-updater.readthedocs.io/)
- [CloudEvents Webhook Setup](https://argocd-image-updater.readthedocs.io/en/stable/configuration/webhooks/)
- [AWS EventBridge Documentation](https://docs.aws.amazon.com/eventbridge/)
