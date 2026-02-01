#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ../deployment-variables.sh

VALUES_FILE="generated-values.yaml"

cat > "$VALUES_FILE" <<EOF
global:
  # DO NOT set imageRegistry globally - it affects Bitnami charts
  # Set registry per-service instead
  imagePullPolicy: Always
  imageVersion: latest
  storageClass: standard
  environment: ${ENVIRONMENT:-development}
  logLevel: ${LOG_LEVEL:-info}

  # PostgreSQL configuration
  postgres:
    host: ${POSTGRES_RELEASE_NAME}-postgresql.${POSTGRES_NAMESPACE}.svc.cluster.local
    port: 5432
    user: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
    sslmode: disable

  # Redis configuration
  redis:
    host: ${REDIS_HOST:-cloudscan-redis-master}
    port: 6379
    authEnabled: true
    password: ${REDIS_PASSWORD}
    secure: ${REDIS_TLS_ENABLED:-false}

  # MinIO/S3 storage configuration
  storage:
    type: ${STORAGE_TYPE}
    s3:
      endpoint: ${MINIO_ENDPOINT:-cloudscan-minio:9000}
      bucket: ${S3_BUCKET:-cloudscan-artifacts}
      region: ${S3_REGION:-us-east-1}
      accessKey: ${MINIO_ACCESS_KEY:-admin}
      secretKey: ${MINIO_SECRET_KEY:-changeme123}
      useSSL: ${S3_USE_SSL:-false}

# On-premise dependencies
onPrem:
  postgresql: false  # Using external PostgreSQL
  redis: ${REDIS_ENABLED}
  minio: ${MINIO_ENABLED:-true}

# PostgreSQL (external - managed separately)
postgresql:
  enabled: false

# Redis
redis:
  enabled: ${REDIS_ENABLED}
  image:
    registry: registry-1.docker.io
    repository: bitnamilegacy/redis
    tag: "8.2.1-debian-12-r0"
  sentinel:
    image:
      registry: registry-1.docker.io
      repository: bitnamilegacy/redis-sentinel
      tag: "8.2.1-debian-12-r0"
  metrics:
    enabled: true
    image:
      registry: registry-1.docker.io
      repository: bitnamilegacy/redis-exporter
      tag: "1.76.0-debian-12-r0"
  volumePermissions:
    image:
      registry: registry-1.docker.io
      repository: bitnamilegacy/os-shell
      tag: "12-debian-12-r51"
  auth:
    enabled: true
    password: ${REDIS_PASSWORD}
  tls:
    enabled: ${REDIS_TLS_ENABLED:-false}
  master:
    persistence:
      enabled: false

# MinIO
minio:
  enabled: ${MINIO_ENABLED:-true}
  mode: standalone
  image:
    registry: registry-1.docker.io
    repository: bitnamilegacy/minio
    tag: "2025.7.23-debian-12-r3"
  clientImage:
    registry: registry-1.docker.io
    repository: bitnamilegacy/minio-client
    tag: "2025.7.21-debian-12-r2"
  defaultInitContainers:
    volumePermissions:
      image:
        registry: registry-1.docker.io
        repository: bitnamilegacy/os-shell
        tag: "12-debian-12-r51"
  console:
    image:
      registry: registry-1.docker.io
      repository: bitnamilegacy/minio-object-browser
      tag: "2.0.2-debian-12-r3"
  auth:
    rootUser: ${MINIO_ACCESS_KEY:-admin}
    rootPassword: ${MINIO_SECRET_KEY:-changeme123}
  defaultBuckets: ${S3_BUCKET:-cloudscan-artifacts}
  persistence:
    enabled: true
    size: 10Gi

orchestrator:
  enabled: ${CLOUDSCAN_ORCHESTRATOR_ENABLED}
  image:
    registry: ${DOCKER_REGISTRY}
    repository: cloudscan-orchestrator
    tag: latest
    pullPolicy: Always
  replicaCount: 1
  postgres:
    database: orchestrator
    maxConns: 25
    minConns: 5
  migration:
    enabled: true
    logLevel: INFO
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

apiGateway:
  enabled: ${CLOUDSCAN_API_GATEWAY_ENABLED}
  image:
    registry: ${DOCKER_REGISTRY}
    repository: cloudscan-api-gateway
    tag: latest
    pullPolicy: Always
  replicaCount: 1
  postgres:
    database: cloudscan_gateway
    maxConns: 25
    minConns: 5
  migration:
    enabled: true
    logLevel: INFO
  jwt:
    secret: ${JWT_SECRET:-changeme-jwt-secret-key-please-change-in-production}
    expirationHours: 24
  rateLimit:
    enabled: true
    requestsPerMinute: 60
  grpc:
    orchestratorTimeout: 30s
    orchestratorTLS: false
    storageTimeout: 30s
    storageTLS: false
  cors:
    allowedOrigins: "*"
    allowedMethods: "GET,POST,PUT,DELETE,OPTIONS"
    allowedHeaders: "Origin,Content-Type,Accept,Authorization"
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

storage:
  enabled: ${CLOUDSCAN_STORAGE_ENABLED}
  image:
    registry: ${DOCKER_REGISTRY}
    repository: cloudscan-storage
    tag: latest
    pullPolicy: Always
  replicaCount: 1
  storageType: ${STORAGE_TYPE}
  defaultExpirationHours: 24
  postgres:
    database: storage
    maxConns: 25
    minConns: 5
  migration:
    enabled: true
    logLevel: INFO
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

websocket:
  enabled: ${CLOUDSCAN_WEBSOCKET_ENABLED}
  image:
    registry: ${DOCKER_REGISTRY}
    repository: cloudscan-websocket
    tag: latest
    pullPolicy: Always
  replicaCount: 1
  service:
    port: 9090
    httpPort: 8083
  cors:
    allowedOrigins: "*"
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

ui:
  enabled: ${CLOUDSCAN_UI_ENABLED}
  image:
    registry: ${DOCKER_REGISTRY}
    repository: cloudscan-ui
    tag: latest
    pullPolicy: Always
  replicaCount: 1
  postgres:
    database: ui_backend
  frontend:
    apiUrl: /api
    wsUrl: /ws
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "250m"

runner:
  enabled: ${CLOUDSCAN_RUNNER_ENABLED}
  image:
    registry: ${DOCKER_REGISTRY}
    repository: cloudscan-runner
    tag: latest
    pullPolicy: Always
  resources:
    requests:
      cpu: 2000m
      memory: 4Gi
    limits:
      cpu: 4000m
      memory: 8Gi
  job:
    ttlSecondsAfterFinished: 3600
    backoffLimit: 1
    activeDeadlineSeconds: 3600

ingress:
  enabled: ${CLOUDSCAN_INGRESS_ENABLED}
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
  hosts:
    - host: ${CLOUDSCAN_INGRESS_HOST}
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: cloudscan-ui
              port: 8080
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: cloudscan-api-gateway
              port: 8080
        - path: /ws
          pathType: Prefix
          backend:
            service:
              name: cloudscan-websocket
              port: 9090
  tls:
    - secretName: cloudscan-tls
      hosts:
        - ${CLOUDSCAN_INGRESS_HOST}

monitoring:
  enabled: ${MONITORING_ENABLED:-true}
  serviceMonitor:
    enabled: false
EOF

echo "Values file generated at: $VALUES_FILE"
cat "$VALUES_FILE"