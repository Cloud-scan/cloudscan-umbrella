
#!/usr/bin/env bash

set -xv
set -euo pipefail

# Load deployment variables
source ./deployment-variables.sh

# Create KIND cluster
pushd kind
  ./create-cluster.sh
popd

# Deploy PostgreSQL
pushd postgres
  ./deploy.sh
popd

echo "Pre-CloudScan requirements completed!"