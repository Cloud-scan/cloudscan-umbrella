#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ../deployment-variables.sh

VALUES_FILE="generated-values.yaml"

# Rebuild values
./build-values.sh "$@"

# Upgrade CloudScan
helm upgrade "$CLOUDSCAN_RELEASE_NAME" "$CLOUDSCAN_CHART_DIR" \
  --namespace "$CLOUDSCAN_NAMESPACE" \
  --values "$VALUES_FILE" \
  --wait \
  --timeout=10m

echo "CloudScan upgraded successfully!"