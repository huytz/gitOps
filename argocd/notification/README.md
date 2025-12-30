# ArgoCD Notifications Configuration

Real-time alerts for application lifecycle events, health status changes, and sync operations.

## Quick Setup

### 1. Configure Slack Integration

```bash
kubectl create secret generic argocd-notifications-secret \
  --from-literal=slack-token=xoxb-your-slack-bot-token \
  -n argocd
```

### 2. Subscribe Projects to Channels

```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.slack: my-channel
```

## Configuration Structure

- **`templates/`**: Message formats (deployment, sync, health)
- **`triggers/`**: Event conditions (created, deleted, sync failed)
- **`services/`**: External integrations (Slack, Teams, Email)
- **`defaultTriggers.yaml`**: Pre-configured trigger combinations

## Key Features

- ✅ **Real-time Alerts**: Instant notifications for critical events
- ✅ **Slack Integration**: Direct channel integration
- ✅ **Lifecycle Events**: Complete application lifecycle coverage
- ✅ **Project-Level**: Granular notification control

## Notification Types

- **Application Lifecycle**: Created, deleted, deployed
- **Health Status**: Degraded, healthy changes
- **Sync Operations**: Running, succeeded, failed, unknown

## Reference

- [ArgoCD Notifications](https://argocd-notifications.readthedocs.io/)
