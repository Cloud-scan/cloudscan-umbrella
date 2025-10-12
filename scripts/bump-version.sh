#!/bin/bash
set -e

# bump-version.sh - Bump chart version (major, minor, or patch)
# Usage: ./bump-version.sh [major|minor|patch]

CHART_FILE="charts/cloudscan/Chart.yaml"

if [ ! -f "$CHART_FILE" ]; then
  echo "Error: Chart.yaml not found at $CHART_FILE"
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: $0 [major|minor|patch]"
  exit 1
fi

BUMP_TYPE=$1

# Extract current version
CURRENT_VERSION=$(grep '^version:' "$CHART_FILE" | awk '{print $2}' | tr -d '"')

if [ -z "$CURRENT_VERSION" ]; then
  echo "Error: Could not extract current version from Chart.yaml"
  exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Split version into components
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Bump version based on type
case $BUMP_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Error: Invalid bump type. Use major, minor, or patch."
    exit 1
    ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo "New version: $NEW_VERSION"

# Update Chart.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version: .*/version: \"$NEW_VERSION\"/" "$CHART_FILE"
else
  # Linux
  sed -i "s/^version: .*/version: \"$NEW_VERSION\"/" "$CHART_FILE"
fi

echo "✓ Chart.yaml updated to version $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff $CHART_FILE"
echo "  2. Commit: git add $CHART_FILE && git commit -m 'Bump version to $NEW_VERSION'"
echo "  3. Tag: git tag v$NEW_VERSION"
echo "  4. Push: git push && git push --tags"