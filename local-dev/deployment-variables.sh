#!/usr/bin/env bash

# CloudScan deployment variables
export CLOUDSCAN_NAMESPACE=${CLOUDSCAN_NAMESPACE:-"cloudscan"}
export CLOUDSCAN_RELEASE_NAME=${CLOUDSCAN_RELEASE_NAME:-"cloudscan"}
export CLOUDSCAN_CHART_DIR=${CLOUDSCAN_CHART_DIR:-"../../charts/cloudscan"}

# KIND cluster settings
export KIND_NODE_IMAGE=${KIND_NODE_IMAGE:-"kindest/node:v1.27.3"}
export REGISTRY_PORT=${REGISTRY_PORT:-"5000"}
export REGISTRY_NAME=${REGISTRY_NAME:-"kind-registry"}
export REGISTRY_IMAGE=${REGISTRY_IMAGE:-"registry:2"}
export CLOUDSCAN_NGINX_NS=${CLOUDSCAN_NGINX_NS:-"ingress-nginx"}

# PostgreSQL settings
export POSTGRES_NAMESPACE=${POSTGRES_NAMESPACE:-"cloudscan"}
export POSTGRES_RELEASE_NAME=${POSTGRES_RELEASE_NAME:-"cloudscan-postgres"}
export POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"cloudscan123"}
export POSTGRES_USER=${POSTGRES_USER:-"cloudscan"}
export POSTGRES_DATABASE=${POSTGRES_DATABASE:-"cloudscan"}

# Redis settings
export REDIS_ENABLED=${REDIS_ENABLED:-"true"}
export REDIS_PASSWORD=${REDIS_PASSWORD:-"redis123"}
export REDIS_HOST=${REDIS_HOST:-"cloudscan-redis-master"}
export REDIS_TLS_ENABLED=${REDIS_TLS_ENABLED:-"false"}

# MinIO settings
export MINIO_ENABLED=${MINIO_ENABLED:-"true"}
export MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY:-"admin"}
export MINIO_SECRET_KEY=${MINIO_SECRET_KEY:-"changeme123"}
export MINIO_ENDPOINT=${MINIO_ENDPOINT:-"http://cloudscan-minio:9000"}

# S3/Storage settings
export STORAGE_TYPE=${STORAGE_TYPE:-"minio"}  # local, s3, minio, gcs, azure
export S3_BUCKET=${S3_BUCKET:-"cloudscan-artifacts"}
export S3_REGION=${S3_REGION:-"us-east-1"}
export S3_USE_SSL=${S3_USE_SSL:-"false"}

# Docker registry settings
export DOCKER_REGISTRY=${DOCKER_REGISTRY:-"docker.io/mahiop123"}
export DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-"latest"}

# Global environment settings
export ENVIRONMENT=${ENVIRONMENT:-"development"}
export LOG_LEVEL=${LOG_LEVEL:-"info"}

# JWT settings
export JWT_SECRET=${JWT_SECRET:-"changeme-jwt-secret-key-please-change-in-production"}

# CloudScan component settings
export CLOUDSCAN_ORCHESTRATOR_ENABLED=${CLOUDSCAN_ORCHESTRATOR_ENABLED:-"true"}
export CLOUDSCAN_API_GATEWAY_ENABLED=${CLOUDSCAN_API_GATEWAY_ENABLED:-"true"}
export CLOUDSCAN_STORAGE_ENABLED=${CLOUDSCAN_STORAGE_ENABLED:-"true"}
export CLOUDSCAN_WEBSOCKET_ENABLED=${CLOUDSCAN_WEBSOCKET_ENABLED:-"true"}
export CLOUDSCAN_UI_ENABLED=${CLOUDSCAN_UI_ENABLED:-"true"}
export CLOUDSCAN_RUNNER_ENABLED=${CLOUDSCAN_RUNNER_ENABLED:-"true"}

# Ingress settings
export CLOUDSCAN_INGRESS_ENABLED=${CLOUDSCAN_INGRESS_ENABLED:-"true"}
export CLOUDSCAN_INGRESS_HOST=${CLOUDSCAN_INGRESS_HOST:-"cloudscan.local"}

# Monitoring settings
export MONITORING_ENABLED=${MONITORING_ENABLED:-"true"}

# Debug settings
export CAPTURE_KIND_LOGS=${CAPTURE_KIND_LOGS:-"true"}
export DEBUG_MODE=${DEBUG_MODE:-"false"}

echo "CloudScan deployment variables loaded:"
echo "  CLOUDSCAN_NAMESPACE: $CLOUDSCAN_NAMESPACE"
echo "  CLOUDSCAN_RELEASE_NAME: $CLOUDSCAN_RELEASE_NAME"
echo "  POSTGRES_DATABASE: $POSTGRES_DATABASE"
echo "  DOCKER_REGISTRY: $DOCKER_REGISTRY"
echo "  STORAGE_TYPE: $STORAGE_TYPE"
echo "  MINIO_ENABLED: $MINIO_ENABLED"
echo "  REDIS_ENABLED: $REDIS_ENABLED"
echo "  CLOUDSCAN_INGRESS_HOST: $CLOUDSCAN_INGRESS_HOST"
echo "  ENVIRONMENT: $ENVIRONMENT"