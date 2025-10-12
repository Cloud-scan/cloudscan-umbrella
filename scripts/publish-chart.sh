#!/bin/bash
set -e

# publish-chart.sh - Package and publish Helm chart to registry
# Usage: ./publish-chart.sh [registry-url]
#
# Environment variables:
#   HELM_REGISTRY_URL - OCI registry URL (e.g., oci://registry.gitlab.com/cloudscan/charts)
#   HELM_REGISTRY_USER - Registry username (optional, for authentication)
#   HELM_REGISTRY_PASSWORD - Registry password (optional, for authentication)

CHART_DIR="charts/cloudscan"
DIST_DIR="dist"

# Use argument or environment variable for registry URL
REGISTRY_URL="${1:-$HELM_REGISTRY_URL}"

if [ -z "$REGISTRY_URL" ]; then
  echo "❌ Error: Registry URL not provided"
  echo ""
  echo "Usage:"
  echo "  $0 oci://registry.gitlab.com/cloudscan/charts"
  echo ""
  echo "Or set environment variable:"
  echo "  export HELM_REGISTRY_URL=oci://registry.gitlab.com/cloudscan/charts"
  exit 1
fi

echo "📦 Publishing CloudScan Helm chart..."
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
  echo "❌ Error: helm is not installed"
  exit 1
fi

echo "✓ Helm installed: $(helm version --short)"
echo "✓ Registry: $REGISTRY_URL"
echo ""

# Authenticate to registry if credentials provided
if [ -n "$HELM_REGISTRY_USER" ] && [ -n "$HELM_REGISTRY_PASSWORD" ]; then
  echo "🔐 Authenticating to registry..."
  echo "$HELM_REGISTRY_PASSWORD" | helm registry login \
    "$(echo "$REGISTRY_URL" | sed 's|oci://||')" \
    --username "$HELM_REGISTRY_USER" \
    --password-stdin
  echo "✓ Authentication successful"
  echo ""
fi

# Create dist directory
mkdir -p "$DIST_DIR"

# Package chart
echo "📦 Packaging chart..."
helm package "$CHART_DIR" --destination "$DIST_DIR"
echo "✓ Chart packaged"
echo ""

# Get package filename
CHART_PACKAGE=$(ls -t "$DIST_DIR"/cloudscan-*.tgz | head -n 1)
CHART_VERSION=$(basename "$CHART_PACKAGE" .tgz | sed 's/cloudscan-//')

echo "✓ Chart: $CHART_PACKAGE"
echo "✓ Version: $CHART_VERSION"
echo ""

# Push to registry
echo "🚀 Pushing chart to registry..."
helm push "$CHART_PACKAGE" "$REGISTRY_URL"
echo "✓ Chart published successfully"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Chart published to registry!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Install with:"
echo "  helm install cloudscan $REGISTRY_URL/cloudscan --version $CHART_VERSION"
echo ""
echo "Or add repository:"
echo "  helm repo add cloudscan https://charts.cloudscan.io"
echo "  helm install cloudscan cloudscan/cloudscan"