#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ../deployment-variables.sh

# Create namespace
kubectl create namespace "$POSTGRES_NAMESPACE" || true

# Add Bitnami Helm repo
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update

# Install PostgreSQL
helm upgrade --install "$POSTGRES_RELEASE_NAME" bitnami/postgresql \
  --namespace "$POSTGRES_NAMESPACE" \
  --set auth.username="$POSTGRES_USER" \
  --set auth.password="$POSTGRES_PASSWORD" \
  --set auth.database="$POSTGRES_DATABASE" \
  --set primary.persistence.enabled=true \
  --set primary.persistence.size=10Gi \
  --set primary.resources.requests.memory=256Mi \
  --set primary.resources.requests.cpu=250m \
  --wait \
  --timeout=5m

echo "PostgreSQL deployed successfully!"
echo "Connection string: postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_RELEASE_NAME-postgresql.$POSTGRES_NAMESPACE.svc.cluster.local:5432/$POSTGRES_DATABASE"