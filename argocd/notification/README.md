
# ArgoCD Notifications Configuration

This directory contains the notification configuration for ArgoCD, providing real-time alerts for application lifecycle events, health status changes, and sync operations.

## Overview

The notification system is configured using Kustomize and includes:
- **Templates**: Message formats for different notification types
- **Triggers**: Conditions that activate notifications
- **Services**: Integration with external notification platforms (Slack, Teams, Email)
- **Default Triggers**: Pre-configured trigger combinations

## Quick Start

### 1. Deploy the Notification Configuration

The notification configuration is automatically deployed via ArgoCD:

```bash
# The configuration is managed by the argocd-notification application
# located in _bootstraps/root/root-argocd-notification.yml
kubectl get application argocd-notification -n argocd
```

### 2. Configure Slack Integration

Create a Slack app and get your bot token from [Slack API](https://api.slack.com/apps).

Apply the secret with your Slack token:

```bash
kubectl create secret generic argocd-notifications-secret \
  --from-literal=slack-token=xoxb-your-slack-bot-token \
  -n argocd
```

### 3. Configure Slack Channels

Add channel subscriptions to your ArgoCD projects using annotations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.slack: my-channel
spec:
  # ... project configuration
```

## Configuration Structure

### Templates (`templates/`)

Message templates for different notification types:

- **app-created.yaml**: Application creation notifications
- **app-deleted.yaml**: Application deletion notifications  
- **app-deployed.yaml**: Successful deployment notifications
- **app-health-degraded.yaml**: Health degradation alerts
- **app-sync-failed.yaml**: Sync failure notifications
- **app-sync-running.yaml**: Sync operation start notifications
- **app-sync-succeeded.yaml**: Successful sync notifications
- **app-sync-status-unknown.yaml**: Unknown sync status notifications

### Triggers (`triggers/`)

Event conditions that activate notifications:

- **on-created.yaml**: Triggers when application is created
- **on-deleted.yaml**: Triggers when application is deleted
- **on-deployed.yaml**: Triggers on successful deployment (once per revision)
- **on-health-degraded.yaml**: Triggers when health status becomes degraded
- **on-sync-failed.yaml**: Triggers on sync failures
- **on-sync-running.yaml**: Triggers when sync operation starts
- **on-sync-succeeded.yaml**: Triggers on successful sync
- **on-sync-status-unknown.yaml**: Triggers on unknown sync status

### Services (`services/`)

External notification platform configurations:

- **slack.yaml**: Slack integration using bot token

### Default Triggers

The `defaultTriggers.yaml` file defines which triggers are enabled by default for all applications.

## Usage Examples

### 1. Project-Level Notifications

Configure notifications for specific projects:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production-apps
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.slack: prod-alerts
    notifications.argoproj.io/subscribe.slack: prod-deployments
spec:
  # ... project configuration
```

### 2. Application-Level Notifications

Override project defaults for specific applications:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: critical-app
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.slack: critical-alerts
    notifications.argoproj.io/subscribe.slack: oncall-team
spec:
  # ... application configuration
```

### 3. Custom Notification Triggers

Create custom triggers for specific events:

```yaml
# Add to triggers/custom-trigger.yaml
- description: Custom trigger for specific conditions
  oncePer: app.metadata.name
  send:
  - custom-template
  when: app.status.health.status == 'Healthy' and app.spec.project == 'production'
```

### 4. Multiple Notification Channels

Send notifications to multiple Slack channels:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
  annotations:
    notifications.argoproj.io/subscribe.slack: general
    notifications.argoproj.io/subscribe.slack: dev-team
    notifications.argoproj.io/subscribe.slack: ops-team
spec:
  # ... project configuration
```

## Notification Types

### Application Lifecycle
- **Created**: New application added to ArgoCD
- **Deleted**: Application removed from ArgoCD
- **Deployed**: Application successfully deployed with new revision

### Health Status
- **Degraded**: Application health status becomes degraded
- **Healthy**: Application returns to healthy state

### Sync Operations
- **Running**: Sync operation started
- **Succeeded**: Sync operation completed successfully
- **Failed**: Sync operation failed
- **Unknown**: Sync status cannot be determined

## Customization

### Adding New Templates

1. Create a new template file in `templates/`:
```yaml
# templates/custom-template.yaml
message: |
  Custom notification for {{.app.metadata.name}}
slack:
  attachments: |
    [{
      "title": "{{ .app.metadata.name}}",
      "color": "#ff0000"
    }]
```

2. Add to `kustomization.yaml`:
```yaml
configMapGenerator:
- name: argocd-notifications-cm
  files:
  - template.custom-template=templates/custom-template.yaml
```

### Adding New Services

1. Create service configuration in `services/`:
```yaml
# services/teams.yaml
webhook: $teams-webhook-url
```

2. Add to `kustomization.yaml`:
```yaml
configMapGenerator:
- name: argocd-notifications-cm
  files:
  - service.teams=services/teams.yaml
```

## Troubleshooting

### Check Notification Status

```bash
# Check if notifications are configured
kubectl get configmap argocd-notifications-cm -n argocd -o yaml

# Check notification controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller

# Test notification delivery
kubectl patch application <app-name> -n argocd --type='merge' -p='{"metadata":{"annotations":{"notifications.argoproj.io/subscribe.slack":"test-channel"}}}'
```

## Reference

- [ArgoCD Notifications Documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/)
- [Slack Integration Guide](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/services/slack/)
- [Template Reference](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/templates/)
- [Trigger Reference](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/triggers/)
