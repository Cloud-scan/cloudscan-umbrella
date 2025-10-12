#!/bin/bash
set -e

# validate-chart.sh - Validate Helm chart before publishing
# Usage: ./validate-chart.sh

CHART_DIR="charts/cloudscan"

echo "🔍 Validating CloudScan Helm chart..."
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
  echo "❌ Error: helm is not installed"
  echo "   Install: https://helm.sh/docs/intro/install/"
  exit 1
fi

echo "✓ Helm installed: $(helm version --short)"
echo ""

# Lint chart
echo "📋 Linting chart..."
helm lint "$CHART_DIR"
echo "✓ Chart lint passed"
echo ""

# Template rendering (dry-run)
echo "🎨 Rendering templates..."
helm template cloudscan "$CHART_DIR" \
  --namespace cloudscan \
  --debug \
  > /dev/null
echo "✓ Template rendering passed"
echo ""

# Validate with different value configurations
echo "🧪 Testing with custom values..."

# Test 1: S3 storage
echo "  → Testing S3 configuration..."
helm template cloudscan "$CHART_DIR" \
  --set storage.type=s3 \
  --set storage.s3.bucket=test-bucket \
  > /dev/null

# Test 2: GCS storage
echo "  → Testing GCS configuration..."
helm template cloudscan "$CHART_DIR" \
  --set storage.type=gcs \
  --set storage.gcs.bucket=test-bucket \
  > /dev/null

# Test 3: Ingress enabled
echo "  → Testing with Ingress enabled..."
helm template cloudscan "$CHART_DIR" \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=cloudscan.example.com \
  > /dev/null

echo "✓ Custom value tests passed"
echo ""

# Check Chart.yaml
echo "📄 Validating Chart.yaml..."
if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
  echo "❌ Error: Chart.yaml not found"
  exit 1
fi

# Extract and validate version
VERSION=$(grep '^version:' "$CHART_DIR/Chart.yaml" | awk '{print $2}' | tr -d '"')
if [ -z "$VERSION" ]; then
  echo "❌ Error: Could not extract version from Chart.yaml"
  exit 1
fi
echo "✓ Chart version: $VERSION"
echo ""

# Check values.yaml
echo "📝 Validating values.yaml..."
if [ ! -f "$CHART_DIR/values.yaml" ]; then
  echo "❌ Error: values.yaml not found"
  exit 1
fi

# Validate YAML syntax
if ! command -v yq &> /dev/null; then
  echo "⚠️  Warning: yq not installed, skipping YAML validation"
  echo "   Install: https://github.com/mikefarah/yq"
else
  yq eval "$CHART_DIR/values.yaml" > /dev/null
  echo "✓ values.yaml syntax valid"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All validations passed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Chart is ready for packaging and publishing."
echo ""
echo "Next steps:"
echo "  ./scripts/publish-chart.sh"