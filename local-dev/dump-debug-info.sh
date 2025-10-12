#!/usr/bin/env bash

set -euo pipefail

# Load deployment variables
source ./deployment-variables.sh

DEBUG_DIR="cloudscan-kind-debug-dump"
mkdir -p "$DEBUG_DIR"

echo "Dumping debug information to $DEBUG_DIR..."

# Dump cluster info
kubectl cluster-info dump > "$DEBUG_DIR/cluster-info.txt" 2>&1 || true

# Dump all resources in cloudscan namespace
kubectl get all -n "$CLOUDSCAN_NAMESPACE" > "$DEBUG_DIR/resources.txt" 2>&1 || true

# Dump pod descriptions
kubectl describe pods -n "$CLOUDSCAN_NAMESPACE" > "$DEBUG_DIR/pod-descriptions.txt" 2>&1 || true

# Dump logs for all pods
for pod in $(kubectl get pods -n "$CLOUDSCAN_NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
  echo "Dumping logs for pod: $pod"
  kubectl logs "$pod" -n "$CLOUDSCAN_NAMESPACE" --all-containers > "$DEBUG_DIR/$pod.log" 2>&1 || true
  kubectl logs "$pod" -n "$CLOUDSCAN_NAMESPACE" --previous --all-containers > "$DEBUG_DIR/$pod-previous.log" 2>&1 || true
done

# Dump events
kubectl get events -n "$CLOUDSCAN_NAMESPACE" --sort-by='.lastTimestamp' > "$DEBUG_DIR/events.txt" 2>&1 || true

# Dump configmaps and secrets (sanitized)
kubectl get configmaps -n "$CLOUDSCAN_NAMESPACE" -o yaml > "$DEBUG_DIR/configmaps.yaml" 2>&1 || true
kubectl get secrets -n "$CLOUDSCAN_NAMESPACE" -o yaml > "$DEBUG_DIR/secrets.yaml" 2>&1 || true

# Dump helm releases
helm list -n "$CLOUDSCAN_NAMESPACE" > "$DEBUG_DIR/helm-releases.txt" 2>&1 || true

echo "Debug information dumped to $DEBUG_DIR/"
echo "Archive created at: ${DEBUG_DIR}.tar.gz"
tar -czf "${DEBUG_DIR}.tar.gz" "$DEBUG_DIR"