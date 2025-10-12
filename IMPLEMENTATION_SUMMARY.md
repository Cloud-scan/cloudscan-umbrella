# CloudScan Umbrella Chart - Implementation Summary

## Overview

This repository implements an **umbrella chart pattern** for the CloudScan platform, similar to the cnc-umbrella-chart reference implementation. It provides:

1. Centralized version management for all services
2. GitHub Actions CI/CD for building and publishing Docker images
3. Automated version updates from individual service repositories
4. Local development environment using KIND (Kubernetes IN Docker)
5. Comprehensive Helm charts for Kubernetes deployment

## Repository Structure

```
cloudscan-umbrella/
├── chart-versions/           # Service version tracking
│   ├── cloudscan.version
│   ├── cloudscan-orchestrator.version
│   ├── cloudscan-api-gateway.version
│   ├── cloudscan-storage.version
│   ├── cloudscan-websocket.version
│   ├── cloudscan-ui.version
│   └── cloudscan-runner.version
│
├── charts/                   # Helm charts
│   └── cloudscan/
│       ├── Chart.yaml        # Umbrella chart definition
│       ├── values.yaml       # Default values for all services
│       └── templates/        # Kubernetes manifests
│
├── local-dev/                # Local development scripts
│   ├── kind/                 # KIND cluster setup
│   │   ├── config.yaml
│   │   ├── create-cluster.sh
│   │   ├── nginx-values.yaml
│   │   └── metrics-server.yaml
│   ├── postgres/             # PostgreSQL deployment
│   │   └── deploy.sh
│   ├── cloudscan/            # CloudScan deployment
│   │   ├── build-values.sh
│   │   ├── deploy.sh
│   │   ├── upgrade.sh
│   │   └── uninstall.sh
│   ├── deployment-variables.sh
│   ├── pre-cloudscan-req.sh
│   ├── post-cloudscan-req.sh
│   ├── deploy-cloudscan.sh
│   ├── uninstall-cloudscan.sh
│   ├── cleanup.sh
│   └── dump-debug-info.sh
│
├── .github/workflows/        # GitHub Actions workflows
│   └── service-template.yml  # Template for service repos
│
├── scripts/                  # Utility scripts
│   └── generate-service-workflows.sh
│
├── pipelines/                # CI/CD pipeline scripts (future)
├── hack/                     # Development tools (future)
└── utils/                    # Utility scripts (future)
```

## Architecture Flow

### 1. Service Development → Docker Image → Version Update

```
┌─────────────────────┐
│  Service Repository │
│ (e.g., orchestrator)│
└──────────┬──────────┘
           │
           │ git push to main
           ▼
┌─────────────────────┐
│  GitHub Actions     │
│  - Build & Test     │
│  - Build Docker img │
│  - Push to Registry │
└──────────┬──────────┘
           │
           │ docker push
           ▼
┌─────────────────────┐
│  Docker Registry    │
│  (Docker Hub/GHCR)  │
└──────────┬──────────┘
           │
           │ version generated
           ▼
┌─────────────────────┐
│  Update Version     │
│  in Umbrella Repo   │
└──────────┬──────────┘
           │
           │ git commit & push
           ▼
┌─────────────────────┐
│  Umbrella Chart     │
│  chart-versions/    │
└─────────────────────┘
```

### 2. Deployment Flow

```
┌─────────────────────┐
│  Umbrella Chart     │
│  values.yaml        │
└──────────┬──────────┘
           │
           │ helm install/upgrade
           ▼
┌─────────────────────────────────────────┐
│         Kubernetes Cluster              │
├─────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐    │
│  │ PostgreSQL   │  │ Redis        │    │
│  │ (Bitnami)    │  │ (Bitnami)    │    │
│  └──────────────┘  └──────────────┘    │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │  CloudScan Services              │  │
│  ├──────────────────────────────────┤  │
│  │  - Orchestrator (gRPC + HTTP)    │  │
│  │  - API Gateway (HTTP)            │  │
│  │  - Storage Service (HTTP)        │  │
│  │  - WebSocket Service (WS)        │  │
│  │  - UI (React SPA)                │  │
│  │  - Runner (K8s Jobs)             │  │
│  └──────────────────────────────────┘  │
│                                          │
│  ┌──────────────────────────────────┐  │
│  │  Ingress                          │  │
│  │  - /     → UI                     │  │
│  │  - /api  → API Gateway            │  │
│  │  - /ws   → WebSocket              │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Key Components

### 1. Version Management

**Location:** `chart-versions/*.version`

Each service has its own version file that gets updated automatically when:
- Service code is pushed to `main` or `release/**` branches
- GitHub Actions builds and pushes Docker images
- Automated commit updates the version file in umbrella repo

**Version Format:**
```
YYYY.MM.COMMIT_COUNT-BRANCH_NAME
```

Example: `2025.10.152-main`

### 2. GitHub Actions Workflows

**Individual Service Repos:**
Each service repository (`cloudscan-orchestrator`, `cloudscan-api-gateway`, etc.) has a `.github/workflows/build-and-publish.yml` that:

1. **Version** - Generates semantic version based on branch and commit count
2. **Build & Test** - Compiles code and runs tests
3. **Build & Push Image** - Creates multi-arch Docker images (amd64, arm64)
4. **Update Umbrella Chart** - Commits new version to `chart-versions/` directory

**Required Secrets:**
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password/token
- `UMBRELLA_REPO_TOKEN` - GitHub token with write access to umbrella repo

### 3. Helm Chart Structure

**Umbrella Chart** (`charts/cloudscan/`)

Aggregates all CloudScan services into a single deployable unit:

```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: postgresql.enabled
  - name: redis
    version: "17.x.x"
    repository: https://charts.bitnami.com/bitnami
    condition: redis.enabled
```

**Values Structure:**
```yaml
global:
  imageRegistry: docker.io
  imagePullPolicy: IfNotPresent

orchestrator:
  enabled: true
  replicaCount: 2
  image:
    repository: cloudscan/cloudscan-orchestrator
    tag: "latest"
  resources: {...}
  env: [...]

apiGateway:
  enabled: true
  ...

# Similar for: storage, websocket, ui, runner
```

### 4. Local Development (KIND)

**Quick Start:**
```bash
cd local-dev
./deploy-cloudscan.sh
```

**What it does:**
1. Creates KIND cluster with local Docker registry
2. Installs NGINX Ingress Controller
3. Deploys PostgreSQL with Bitnami chart
4. Generates Helm values from environment variables
5. Installs CloudScan using umbrella chart
6. Configures ingress for http://cloudscan.local

**Features:**
- Local Docker registry at `localhost:5000`
- Persistent PostgreSQL data
- Hot-reload capable (rebuild image → push → upgrade)
- Debug information collection
- Easy cleanup

## Usage Instructions

### For Service Developers

1. **Make changes to a service** (e.g., `cloudscan-orchestrator`)
2. **Commit and push to `main` branch**
   ```bash
   git add .
   git commit -m "Add new feature"
   git push origin main
   ```
3. **GitHub Actions automatically:**
   - Builds Docker image
   - Pushes to Docker Hub
   - Updates version in `cloudscan-umbrella/chart-versions/cloudscan-orchestrator.version`
4. **Check umbrella repo** for version update commit

### For Platform Developers

1. **Clone umbrella repo**
   ```bash
   git clone https://github.com/cloudscan/cloudscan-umbrella
   cd cloudscan-umbrella
   ```

2. **Deploy locally**
   ```bash
   cd local-dev
   ./deploy-cloudscan.sh
   ```

3. **Access CloudScan**
   - Add to `/etc/hosts`: `127.0.0.1 cloudscan.local`
   - Open: http://cloudscan.local

4. **Make chart changes**
   ```bash
   # Edit charts/cloudscan/values.yaml
   cd local-dev/cloudscan
   ./upgrade.sh
   ```

### For Production Deployment

1. **Add Helm repo** (once published)
   ```bash
   helm repo add cloudscan https://charts.cloudscan.dev
   helm repo update
   ```

2. **Install CloudScan**
   ```bash
   helm install cloudscan cloudscan/cloudscan \
     --namespace cloudscan \
     --create-namespace \
     --set postgresql.auth.password=STRONG_PASSWORD \
     --set ingress.hosts[0].host=cloudscan.example.com \
     --set global.imageRegistry=docker.io
   ```

3. **Configure DNS**
   ```bash
   # Point cloudscan.example.com to Ingress LoadBalancer IP
   kubectl get ingress -n cloudscan
   ```

## Comparison with Reference Implementation

| Feature | cnc-umbrella-chart | cloudscan-umbrella |
|---------|-------------------|-------------------|
| **Version Files** | `chart-versions/*.version` | ✅ Same pattern |
| **CI/CD** | GitLab CI | GitHub Actions |
| **Local Dev** | KinD scripts | ✅ Adapted for CloudScan |
| **Helm Structure** | Umbrella chart | ✅ Same pattern |
| **Registry** | GCR (Google) | Docker Hub/GHCR |
| **Version Format** | `YYYY.MM.BUILD-BRANCH` | ✅ Same format |
| **Auto-update** | GitLab CI job | GitHub Actions workflow |
| **Notifications** | Slack/Teams | GitHub only (no Teams) |

## Next Steps

### Immediate
- [ ] Create GitHub repositories for all services
- [ ] Set up GitHub secrets for Docker Hub and umbrella repo access
- [ ] Push initial code to service repositories
- [ ] Test GitHub Actions workflows
- [ ] Verify version updates work

### Short-term
- [ ] Create Kubernetes manifests (templates/) for each service
- [ ] Add ServiceAccount and RBAC templates
- [ ] Implement health checks and readiness probes
- [ ] Add NetworkPolicies for security
- [ ] Create CI workflow for umbrella chart itself

### Long-term
- [ ] Add Prometheus ServiceMonitors
- [ ] Implement autoscaling (HPA)
- [ ] Add cert-manager for TLS
- [ ] Create production-ready values files
- [ ] Publish Helm chart to OCI registry
- [ ] Add integration tests
- [ ] Create Grafana dashboards

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with KIND
5. Submit a pull request

## Support

- GitHub Issues: https://github.com/cloudscan/cloudscan-umbrella/issues
- Documentation: https://docs.cloudscan.dev
- Community: https://discord.gg/cloudscan

## License

Apache 2.0 License - See LICENSE file for details