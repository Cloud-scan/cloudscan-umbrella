#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ../deployment-variables.sh

# Uninstall CloudScan Helm release
helm uninstall "$CLOUDSCAN_RELEASE_NAME" -n "$CLOUDSCAN_NAMESPACE" || true

echo "CloudScan uninstalled!"