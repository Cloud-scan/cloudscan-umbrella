#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ../deployment-variables.sh

# Build image versions from chart-versions directory
./build-image-versions-values.sh

VALUES_FILE="generated-values.yaml"
IMAGE_VERSIONS_FILE="image-versions-values.yaml"

# Create namespace
kubectl create namespace "$CLOUDSCAN_NAMESPACE" || true

# Generate TLS certificates if they don't exist
if [ ! -f ../certs/tls.crt ] || [ ! -f ../certs/tls.key ]; then
  echo "Generating self-signed TLS certificates..."
  pushd ../certs
  ./create-new-cert.sh
  popd
fi

# Create TLS secret for ingress
kubectl create secret tls cloudscan-tls \
  --namespace "$CLOUDSCAN_NAMESPACE" \
  --cert=../certs/tls.crt \
  --key=../certs/tls.key \
  -o yaml --dry-run=client | kubectl apply -f -

# Delete existing secrets to avoid Helm ownership conflicts
kubectl delete secret cloudscan-postgresql cloudscan-redis \
  --namespace "$CLOUDSCAN_NAMESPACE" \
  --ignore-not-found=true

# Create PostgreSQL secret with Helm ownership labels
kubectl create secret generic cloudscan-postgresql \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=password="$POSTGRES_PASSWORD" \
  --from-literal=username="$POSTGRES_USER" \
  --from-literal=database="$POSTGRES_DATABASE" \
  --namespace "$CLOUDSCAN_NAMESPACE" \
  --dry-run=client -o yaml | \
  kubectl label --local -f - app.kubernetes.io/managed-by=Helm -o yaml | \
  kubectl annotate --local -f - meta.helm.sh/release-name="$CLOUDSCAN_RELEASE_NAME" -o yaml | \
  kubectl annotate --local -f - meta.helm.sh/release-namespace="$CLOUDSCAN_NAMESPACE" -o yaml | \
  kubectl apply -f -

# Create Redis secret with Helm ownership labels
kubectl create secret generic cloudscan-redis \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --namespace "$CLOUDSCAN_NAMESPACE" \
  --dry-run=client -o yaml | \
  kubectl label --local -f - app.kubernetes.io/managed-by=Helm -o yaml | \
  kubectl annotate --local -f - meta.helm.sh/release-name="$CLOUDSCAN_RELEASE_NAME" -o yaml | \
  kubectl annotate --local -f - meta.helm.sh/release-namespace="$CLOUDSCAN_NAMESPACE" -o yaml | \
  kubectl apply -f -

echo "Secrets created successfully with Helm ownership metadata"

# Install or upgrade CloudScan
helm upgrade --install "$CLOUDSCAN_RELEASE_NAME" "$CLOUDSCAN_CHART_DIR" \
  --namespace "$CLOUDSCAN_NAMESPACE" \
  --values "$VALUES_FILE" \
  --values "$IMAGE_VERSIONS_FILE" \
  --wait \
  --timeout=10m \
  --create-namespace

echo "CloudScan deployed successfully!"