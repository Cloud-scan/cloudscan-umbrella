# CloudScan Helm Chart

Helm chart for deploying CloudScan on Kubernetes.

## Prerequisites

- Kubernetes 1.28+
- Helm 3.x
- Storage bucket (S3/GCS/Azure)

## Installation

```bash
# Add repository
helm repo add cloudscan https://charts.cloudscan.dev
helm repo update

# Install with default values
helm install cloudscan cloudscan/cloudscan \
  --namespace cloudscan \
  --create-namespace

# Install with custom values
helm install cloudscan cloudscan/cloudscan \
  --namespace cloudscan \
  --create-namespace \
  --set postgresql.auth.password=securepassword \
  --set storage.type=s3 \
  --set storage.s3.bucket=my-bucket \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=cloudscan.mycompany.com
```

## Configuration

Key parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `orchestrator.replicaCount` | Number of orchestrator replicas | `3` |
| `ui.replicaCount` | Number of UI replicas | `2` |
| `storage.type` | Storage backend (s3/gcs/azure) | `s3` |
| `storage.s3.bucket` | S3 bucket name | `""` |
| `postgresql.enabled` | Deploy PostgreSQL | `true` |
| `ingress.enabled` | Enable ingress | `false` |

See [values.yaml](values.yaml) for all parameters.

## Uninstall

```bash
helm uninstall cloudscan --namespace cloudscan
```