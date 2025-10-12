#!/bin/bash
# Build and push all CloudScan services as multiarch images with version 1.0.0
# Usage: ./build-and-push-all-v1.0.0.sh

set -e

# Configuration
DOCKER_REGISTRY="docker.io"
DOCKER_ORG="mahiop123"
VERSION="1.0.0"
PLATFORMS="linux/amd64,linux/arm64"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Services
SERVICES=(
  "cloudscan-orchestrator"
  "cloudscan-runner"
  "cloudscan-storage"
  "cloudscan-api-gateway"
  "cloudscan-websocket"
  "cloudscan-ui"
)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CloudScan Multiarch Build & Push${NC}"
echo -e "${GREEN}Version: ${VERSION}${NC}"
echo -e "${GREEN}Registry: ${DOCKER_REGISTRY}/${DOCKER_ORG}${NC}"
echo -e "${GREEN}Platforms: ${PLATFORMS}${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check Docker is running
if ! docker info > /dev/null 2>&1; then
  echo -e "${RED}Error: Docker is not running${NC}"
  exit 1
fi

# Check buildx
if ! docker buildx version > /dev/null 2>&1; then
  echo -e "${RED}Error: docker buildx is not available${NC}"
  exit 1
fi

# Create/use buildx builder
if ! docker buildx ls | grep -q "cloudscan-builder"; then
  echo -e "${BLUE}Creating buildx builder...${NC}"
  docker buildx create --name cloudscan-builder --use
  docker buildx inspect --bootstrap
else
  echo -e "${BLUE}Using existing buildx builder...${NC}"
  docker buildx use cloudscan-builder
fi

# Login to Docker Hub
echo -e "${BLUE}Logging in to Docker Hub...${NC}"
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
  echo -e "${YELLOW}DOCKER_USERNAME and DOCKER_PASSWORD not set in environment${NC}"
  echo -e "${YELLOW}Please login manually:${NC}"
  docker login ${DOCKER_REGISTRY}
else
  echo "$DOCKER_PASSWORD" | docker login ${DOCKER_REGISTRY} -u "$DOCKER_USERNAME" --password-stdin
fi

echo ""

# Build and push each service
for SERVICE in "${SERVICES[@]}"; do
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}Building ${SERVICE}...${NC}"
  echo -e "${YELLOW}========================================${NC}"

  SERVICE_DIR="${SERVICE}"

  if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}Error: Directory ${SERVICE_DIR} not found${NC}"
    echo -e "${YELLOW}Skipping ${SERVICE}${NC}"
    echo ""
    continue
  fi

  cd "$SERVICE_DIR"

  # Build and push
  IMAGE_NAME="${DOCKER_REGISTRY}/${DOCKER_ORG}/${SERVICE}"

  echo -e "${BLUE}Building and pushing: ${IMAGE_NAME}:${VERSION}${NC}"

  if docker buildx build \
    --platform ${PLATFORMS} \
    --tag ${IMAGE_NAME}:${VERSION} \
    --tag ${IMAGE_NAME}:latest \
    --push \
    .; then
    echo -e "${GREEN}✓ ${SERVICE} built and pushed successfully${NC}"
  else
    echo -e "${RED}✗ ${SERVICE} build failed${NC}"
    cd ..
    exit 1
  fi

  cd ..
  echo ""
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All services built and pushed!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Images pushed to ${DOCKER_REGISTRY}/${DOCKER_ORG}:"
for SERVICE in "${SERVICES[@]}"; do
  echo "  - ${SERVICE}:${VERSION}"
  echo "  - ${SERVICE}:latest"
done

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update chart-versions/*.version files in cloudscan-umbrella with: ${VERSION}"
echo "2. Deploy with: cd cloudscan-umbrella/local-dev && ./deploy-cloudscan.sh"
echo ""
echo -e "${BLUE}Verify images:${NC}"
for SERVICE in "${SERVICES[@]}"; do
  echo "  docker manifest inspect ${DOCKER_REGISTRY}/${DOCKER_ORG}/${SERVICE}:${VERSION}"
done