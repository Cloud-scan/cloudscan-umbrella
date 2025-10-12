# CloudScan Docker Build Guide

This guide provides instructions for building Docker images for all CloudScan services.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Service Overview](#service-overview)
- [Building Individual Services](#building-individual-services)
- [Building All Services](#building-all-services)
- [Multi-Architecture Builds](#multi-architecture-builds)
- [Testing Locally](#testing-locally)

## Prerequisites

- Docker 20.10+ or Docker Desktop
- Docker Buildx (for multi-arch builds)
- Git
- Make (for Go services)

## Service Overview

CloudScan consists of 6 microservices:

| Service | Language | Dockerfile | Makefile | Port(s) |
|---------|----------|------------|----------|---------|
| orchestrator | Go | ✅ | ✅ | 9999 (gRPC), 8081 (HTTP) |
| runner | Go | ✅ | ✅ | 8083 |
| storage | Go | ✅ | ✅ | 8082 |
| api-gateway | Go/Spring Boot | ✅ (both) | ✅ | 8080 |
| websocket | Go/Node.js | ✅ (both) | ✅ | 9090 |
| ui | React | ✅ | N/A | 3000 |

## Building Individual Services

### Go Services (orchestrator, runner, storage, api-gateway, websocket)

Each Go service has a Makefile for local builds:

```bash
# Build for Linux (both amd64 and arm64)
cd cloudscan-<service>
make linux

# Build for macOS
make darwin

# Clean build artifacts
make clean

# Run tests
make test
```

**Build Docker Image:**

```bash
cd cloudscan-<service>
docker build -t cloudscan/<service>:latest .
```

**Multi-arch Docker Build:**

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t cloudscan/<service>:latest \
  --push .
```

### Spring Boot Services (api-gateway alternative)

If using Spring Boot for API Gateway:

```bash
cd cloudscan-api-gateway
docker build -f Dockerfile.springboot -t cloudscan/api-gateway:latest .
```

### Node.js Services (websocket alternative)

If using Node.js for WebSocket:

```bash
cd cloudscan-websocket
docker build -f Dockerfile.nodejs -t cloudscan/websocket:latest .
```

### React UI

```bash
cd cloudscan-ui
docker build \
  --build-arg REACT_APP_API_URL=http://localhost:8080 \
  --build-arg REACT_APP_WS_URL=ws://localhost:9090 \
  -t cloudscan/ui:latest .
```

## Building All Services

Create a script to build all services:

```bash
#!/bin/bash
set -e

SERVICES=("orchestrator" "runner" "storage" "api-gateway" "websocket" "ui")
VERSION=${VERSION:-latest}

for service in "${SERVICES[@]}"; do
  echo "Building cloudscan-${service}..."
  cd cloudscan-${service}
  docker build -t cloudscan/${service}:${VERSION} .
  cd ..
done

echo "All services built successfully!"
```

## Multi-Architecture Builds

### Setup Buildx

```bash
# Create a new builder instance
docker buildx create --name cloudscan-builder --use

# Verify builder
docker buildx inspect --bootstrap
```

### Build and Push Multi-Arch Images

```bash
#!/bin/bash
set -e

REGISTRY=${REGISTRY:-docker.io/cloudscan}
VERSION=${VERSION:-latest}
SERVICES=("orchestrator" "runner" "storage" "api-gateway" "websocket" "ui")

for service in "${SERVICES[@]}"; do
  echo "Building multi-arch image for ${service}..."
  cd cloudscan-${service}

  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ${REGISTRY}/${service}:${VERSION} \
    -t ${REGISTRY}/${service}:latest \
    --push \
    .

  cd ..
done

echo "All multi-arch images built and pushed!"
```

## Testing Locally

### 1. Build Images Locally

```bash
# Build for your local architecture
docker build -t cloudscan/orchestrator:test ./cloudscan-orchestrator
docker build -t cloudscan/runner:test ./cloudscan-runner
docker build -t cloudscan/storage:test ./cloudscan-storage
docker build -t cloudscan/api-gateway:test ./cloudscan-api-gateway
docker build -t cloudscan/websocket:test ./cloudscan-websocket
docker build -t cloudscan/ui:test ./cloudscan-ui
```

### 2. Test with Docker Compose

Create a `docker-compose.test.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: cloudscan
      POSTGRES_USER: cloudscan
      POSTGRES_PASSWORD: changeme
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass redis123
    ports:
      - "6379:6379"

  orchestrator:
    image: cloudscan/orchestrator:test
    ports:
      - "9999:9999"
      - "8081:8081"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: cloudscan
      DB_USER: cloudscan
      DB_PASSWORD: changeme
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: redis123
    depends_on:
      - postgres
      - redis

  storage:
    image: cloudscan/storage:test
    ports:
      - "8082:8082"
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: cloudscan
      DB_USER: cloudscan
      DB_PASSWORD: changeme
    depends_on:
      - postgres

  api-gateway:
    image: cloudscan/api-gateway:test
    ports:
      - "8080:8080"
    environment:
      ORCHESTRATOR_URL: http://orchestrator:8081
      STORAGE_URL: http://storage:8082
    depends_on:
      - orchestrator
      - storage

  websocket:
    image: cloudscan/websocket:test
    ports:
      - "9090:9090"
    depends_on:
      - api-gateway

  ui:
    image: cloudscan/ui:test
    ports:
      - "3000:3000"
    depends_on:
      - api-gateway
      - websocket
```

Run the stack:

```bash
docker-compose -f docker-compose.test.yml up
```

### 3. Test with KIND (Kubernetes in Docker)

Use the existing KIND scripts:

```bash
cd cloudscan-umbrella/local-dev
./deploy-cloudscan.sh
```

## Troubleshooting

### Build Failures

1. **Go build errors**: Ensure go.mod and go.sum are present
   ```bash
   cd cloudscan-<service>
   go mod init github.com/yourusername/cloudscan-<service>
   go mod tidy
   ```

2. **Docker build context too large**: Create `.dockerignore`
   ```
   .git
   .github
   node_modules
   dist
   build
   *.log
   ```

3. **Multi-arch build issues**: Ensure QEMU is installed
   ```bash
   docker run --privileged --rm tonistiigi/binfmt --install all
   ```

### Runtime Issues

1. **Health checks failing**: Verify the service is listening on the expected port
2. **Permission errors**: Ensure volumes have correct permissions (user 1000:1000)
3. **Network connectivity**: Check service names match Kubernetes service names

## Image Optimization Tips

1. **Use multi-stage builds**: Already implemented in all Dockerfiles
2. **Minimize layers**: Combine RUN commands where possible
3. **Use .dockerignore**: Exclude unnecessary files
4. **Use specific base image versions**: Already using versioned tags (alpine:3.19, node:20-alpine)
5. **Run as non-root**: All Dockerfiles use non-root user (cloudscan:1000)

## Security Best Practices

All Dockerfiles follow these security practices:

- ✅ Multi-stage builds to minimize final image size
- ✅ Non-root user (cloudscan:1000)
- ✅ Specific base image versions (no :latest)
- ✅ Health checks configured
- ✅ Minimal runtime dependencies
- ✅ No secrets in images (use environment variables)

## Next Steps

1. Build all images locally: `make linux` in each Go service
2. Test Docker builds: `docker build -t test .`
3. Push to registry: Use GitHub Actions (already configured)
4. Deploy to KIND: Use local-dev scripts
5. Deploy to production: Use Helm charts

## Related Documentation

- [Helm Chart Documentation](charts/cloudscan/README.md)
- [Local Development Guide](local-dev/README_LOCAL_DEV.md)
- [GitHub Actions Workflows](.github/workflows/build-and-publish.yml)