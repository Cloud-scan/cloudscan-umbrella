#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ./deployment-variables.sh

# Uninstall CloudScan
./uninstall-cloudscan.sh

# Delete KIND cluster
kind delete cluster || true

# Stop and remove registry
docker stop "$REGISTRY_NAME" || true
docker rm "$REGISTRY_NAME" || true

echo "Cleanup complete!"