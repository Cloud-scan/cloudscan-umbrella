# CloudScan Umbrella Chart - Local Development Guide

This guide explains how to develop and test CloudScan locally using KIND (Kubernetes IN Docker).

## Prerequisites

- Docker Desktop or Docker Engine
- kubectl
- helm
- kind
- Git

## Quick Start

### 1. Create KIND Cluster and Deploy CloudScan

```bash
cd local-dev
./deploy-cloudscan.sh
```

This script will:
1. Create a KIND cluster with local registry
2. Install NGINX Ingress Controller
3. Deploy PostgreSQL
4. Deploy CloudScan services
5. Configure ingress

### 2. Access CloudScan UI

Add the following to your `/etc/hosts` file:

```bash
echo '127.0.0.1 cloudscan.local' | sudo tee -a /etc/hosts
```

Then open: http://cloudscan.local

## Manual Deployment Steps

### 1. Create KIND Cluster

```bash
cd local-dev/kind
./create-cluster.sh
```

### 2. Deploy Prerequisites

```bash
cd local-dev
./pre-cloudscan-req.sh
```

This deploys:
- KIND cluster
- Local Docker registry
- NGINX Ingress Controller
- PostgreSQL database

### 3. Deploy CloudScan

```bash
cd local-dev/cloudscan
./build-values.sh
./deploy.sh
```

### 4. Verify Deployment

```bash
kubectl get pods -n cloudscan
kubectl get services -n cloudscan
kubectl get ingress -n cloudscan
```

## Cleanup

### Uninstall CloudScan

```bash
cd local-dev
./uninstall-cloudscan.sh
```

### Delete KIND Cluster and Registry

```bash
cd local-dev
./cleanup.sh
```

## Configuration

### Environment Variables

Edit `local-dev/deployment-variables.sh` to customize:

- `CLOUDSCAN_NAMESPACE`: Kubernetes namespace (default: cloudscan)
- `POSTGRES_PASSWORD`: PostgreSQL password
- `DOCKER_REGISTRY`: Docker registry URL (default: localhost:5000)
- `CLOUDSCAN_INGRESS_HOST`: Ingress hostname (default: cloudscan.local)
- `STORAGE_TYPE`: Storage backend (local, s3, gcs, azure)

### Custom Values

Modify `local-dev/cloudscan/generated-values.yaml` after running `build-values.sh`, then run:

```bash
cd local-dev/cloudscan
./upgrade.sh
```

## Debugging

### View Logs

```bash
# All pods in cloudscan namespace
kubectl logs -f -n cloudscan -l app=cloudscan-orchestrator

# Specific service
kubectl logs -f -n cloudscan deployment/cloudscan-ui
```

### Dump Debug Information

```bash
cd local-dev
./dump-debug-info.sh
```

This creates `cloudscan-kind-debug-dump/` with:
- Cluster info
- Pod descriptions
- Logs from all pods
- Events
- ConfigMaps and Secrets

### Port Forwarding

```bash
# PostgreSQL
kubectl port-forward -n cloudscan svc/cloudscan-postgresql 5432:5432

# API Gateway
kubectl port-forward -n cloudscan svc/cloudscan-api-gateway 8080:8080

# WebSocket
kubectl port-forward -n cloudscan svc/cloudscan-websocket 9090:9090
```

## Development Workflow

### Testing Local Changes

1. Build and push images to local registry:

```bash
# Example for orchestrator service
cd ../cloudscan-orchestrator
docker build -t localhost:5000/cloudscan-orchestrator:dev .
docker push localhost:5000/cloudscan-orchestrator:dev
```

2. Update values and upgrade:

```bash
cd local-dev/cloudscan
# Edit generated-values.yaml to use :dev tag
./upgrade.sh
```

### Testing Scanners

1. Port-forward to API Gateway:

```bash
kubectl port-forward -n cloudscan svc/cloudscan-api-gateway 8080:8080
```

2. Create a scan via API:

```bash
curl -X POST http://localhost:8080/api/v1/scans \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "proj-123",
    "source": {
      "type": "git",
      "repository": "https://github.com/example/repo",
      "branch": "main"
    },
    "scan_types": ["sast", "sca", "secrets"]
  }'
```

## Troubleshooting

### Pods in CrashLoopBackOff

```bash
# Check pod logs
kubectl logs -n cloudscan <pod-name>

# Check pod events
kubectl describe pod -n cloudscan <pod-name>

# Check if database is ready
kubectl get pods -n cloudscan -l app.kubernetes.io/name=postgresql
```

###Ingress not working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl get ingress -n cloudscan -o yaml

# Test ingress locally
curl -H "Host: cloudscan.local" http://localhost/
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl run -it --rm debug --image=postgres:14 --restart=Never -- \
  psql postgresql://cloudscan:cloudscan123@cloudscan-postgresql:5432/cloudscan
```

## Scripts Reference

| Script | Description |
|--------|-------------|
| `deploy-cloudscan.sh` | Full deployment (cluster + cloudscan) |
| `pre-cloudscan-req.sh` | Deploy prerequisites only |
| `post-cloudscan-req.sh` | Post-deployment tasks |
| `uninstall-cloudscan.sh` | Uninstall CloudScan |
| `cleanup.sh` | Delete cluster and registry |
| `dump-debug-info.sh` | Collect debug information |
| `kind/create-cluster.sh` | Create KIND cluster |
| `postgres/deploy.sh` | Deploy PostgreSQL |
| `cloudscan/build-values.sh` | Generate values file |
| `cloudscan/deploy.sh` | Deploy CloudScan chart |
| `cloudscan/upgrade.sh` | Upgrade CloudScan |
| `cloudscan/uninstall.sh` | Uninstall CloudScan only |

## Next Steps

- Configure storage backend (S3/GCS/Azure)
- Enable TLS/SSL with cert-manager
- Configure authentication providers
- Set up monitoring with Prometheus/Grafana
- Deploy to production Kubernetes cluster