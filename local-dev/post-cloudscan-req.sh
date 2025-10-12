#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ./deployment-variables.sh

echo "Post-CloudScan deployment tasks..."

# Wait for all pods to be ready
echo "Waiting for CloudScan pods to be ready..."
kubectl wait --for=condition=ready pod \
  --all \
  -n "$CLOUDSCAN_NAMESPACE" \
  --timeout=300s || true

# Display deployment status
echo "CloudScan deployment status:"
kubectl get pods -n "$CLOUDSCAN_NAMESPACE"
kubectl get services -n "$CLOUDSCAN_NAMESPACE"
kubectl get ingress -n "$CLOUDSCAN_NAMESPACE"

echo ""
echo "CloudScan is deployed!"
echo "Access the UI at: http://$CLOUDSCAN_INGRESS_HOST"
echo ""
echo "To add the host to /etc/hosts, run:"
echo "  echo '127.0.0.1 $CLOUDSCAN_INGRESS_HOST' | sudo tee -a /etc/hosts"
echo ""