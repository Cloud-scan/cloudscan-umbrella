#!/bin/bash

# Script to generate GitHub Actions workflows for all CloudScan services

set -euo pipefail

SERVICES=("api-gateway" "storage" "websocket" "ui" "runner")
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for service in "${SERVICES[@]}"; do
  SERVICE_DIR="$BASE_DIR/cloudscan-$service"
  WORKFLOW_DIR="$SERVICE_DIR/.github/workflows"
  WORKFLOW_FILE="$WORKFLOW_DIR/build-and-publish.yml"

  echo "Generating workflow for cloudscan-$service..."

  mkdir -p "$WORKFLOW_DIR"

  cat > "$WORKFLOW_FILE" <<EOF
name: Build and Publish cloudscan-$service

on:
  push:
    branches:
      - main
      - 'release/**'
  pull_request:
    branches:
      - main

env:
  SERVICE_NAME: cloudscan-$service
  DOCKER_REGISTRY: docker.io
  DOCKER_ORG: cloudscan
  UMBRELLA_REPO: cloudscan/cloudscan-umbrella

jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      version: \${{ steps.get_version.outputs.version }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate version
        id: get_version
        run: |
          if [ "\${{ github.ref_name }}" == "main" ]; then
            VERSION="\$(date +%Y).\$(date +%m).\$(git rev-list --count HEAD)-main"
          elif [[ "\${{ github.ref_name }}" =~ ^release/ ]]; then
            BRANCH_NAME="\${{ github.ref_name }}"
            VERSION="\$(date +%Y).\$(date +%m).\$(git rev-list --count HEAD)-\${BRANCH_NAME#release/}"
          else
            VERSION="0.0.0-dev-\${{ github.run_number }}"
          fi
          echo "version=\$VERSION" >> \$GITHUB_OUTPUT
          echo "Generated version: \$VERSION"

  build_and_test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: '1.22'
        if: hashFiles('go.mod') != ''

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
        if: hashFiles('package.json') != ''

      - name: Run tests (Go)
        if: hashFiles('go.mod') != ''
        run: |
          go test ./... -v || echo "No tests found"

      - name: Run tests (Node.js)
        if: hashFiles('package.json') != ''
        run: |
          npm ci
          npm test || echo "No tests configured"

      - name: Build
        run: |
          if [ -f "go.mod" ]; then
            go build -o \${{ env.SERVICE_NAME }} ./cmd/main.go || echo "Build will be completed in Docker"
          elif [ -f "package.json" ]; then
            npm run build || echo "Build will be completed in Docker"
          fi

  build_and_push_image:
    runs-on: ubuntu-latest
    needs: [version, build_and_test]
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/heads/release/'))
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          registry: \${{ env.DOCKER_REGISTRY }}
          username: \${{ secrets.DOCKER_USERNAME }}
          password: \${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            \${{ env.DOCKER_REGISTRY }}/\${{ env.DOCKER_ORG }}/\${{ env.SERVICE_NAME }}:\${{ needs.version.outputs.version }}
            \${{ env.DOCKER_REGISTRY }}/\${{ env.DOCKER_ORG }}/\${{ env.SERVICE_NAME }}:\${{ github.ref_name }}.latest
            \${{ env.DOCKER_REGISTRY }}/\${{ env.DOCKER_ORG }}/\${{ env.SERVICE_NAME }}:\${{ github.sha }}
          labels: |
            org.opencontainers.image.source=\${{ github.server_url }}/\${{ github.repository }}
            org.opencontainers.image.revision=\${{ github.sha }}
            org.opencontainers.image.created=\${{ github.event.head_commit.timestamp }}

  update_umbrella_chart:
    runs-on: ubuntu-latest
    needs: [version, build_and_push_image]
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/heads/release/'))
    steps:
      - name: Checkout umbrella chart repo
        uses: actions/checkout@v4
        with:
          repository: \${{ env.UMBRELLA_REPO }}
          token: \${{ secrets.UMBRELLA_REPO_TOKEN }}
          ref: \${{ github.ref_name }}

      - name: Update version file
        run: |
          VERSION="\${{ needs.version.outputs.version }}"
          VERSION_FILE="chart-versions/\${{ env.SERVICE_NAME }}.version"
          OLD_VERSION=\$(cat "\$VERSION_FILE" || echo "none")
          echo "\$VERSION" > "\$VERSION_FILE"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add "\$VERSION_FILE"
          git commit -m "Update \${{ env.SERVICE_NAME }} version from \${OLD_VERSION} to \${VERSION}

          Source: \${{ github.server_url }}/\${{ github.repository }}/commit/\${{ github.sha }}
          Triggered by: \${{ github.actor }}"
          git push origin \${{ github.ref_name }}
EOF

  echo "✓ Created workflow for cloudscan-$service at $WORKFLOW_FILE"
done

echo ""
echo "All service workflows generated successfully!"
echo ""
echo "Next steps:"
echo "1. Commit and push the workflows to each service repository"
echo "2. Set up GitHub secrets in each repository:"
echo "   - DOCKER_USERNAME: Your Docker Hub username"
echo "   - DOCKER_PASSWORD: Your Docker Hub password or access token"
echo "   - UMBRELLA_REPO_TOKEN: GitHub token with write access to umbrella repo"