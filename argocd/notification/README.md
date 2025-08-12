# ArgoCD Notifications Configuration

This directory contains the notification configuration for ArgoCD.

## Slack Configuration

To configure Slack notifications, create a secret with your Slack token:

Apply the secret:
```bash
echo 'apiVersion: v1
kind: Secret
metadata:
  name: argocd-notifications-secret
  namespace: argocd
stringData:
  slack-token: <your-slack-token-here>' | kubectl apply -f -
```

## Templates and Triggers

The notification templates and triggers are configured in the ConfigMap `argocd-notifications-cm`. This includes:

- Application lifecycle notifications (created, deleted, deployed)
- Health status notifications (degraded)
- Sync status notifications (running, succeeded, failed, unknown)
