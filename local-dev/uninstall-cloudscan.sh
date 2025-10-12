#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ./deployment-variables.sh

echo "Uninstalling CloudScan..."

# Uninstall CloudScan Helm release
helm uninstall "$CLOUDSCAN_RELEASE_NAME" -n "$CLOUDSCAN_NAMESPACE" || true

# Uninstall PostgreSQL
helm uninstall "$POSTGRES_RELEASE_NAME" -n "$POSTGRES_NAMESPACE" || true

# Delete namespace
kubectl delete namespace "$CLOUDSCAN_NAMESPACE" || true

# Delete PVCs
kubectl delete pvc --all -n "$CLOUDSCAN_NAMESPACE" || true

echo "CloudScan uninstalled successfully!"