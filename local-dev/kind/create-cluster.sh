#!/bin/bash

set -xv
set -euo pipefail

# Default values
KIND_NODE_IMAGE=${KIND_NODE_IMAGE:-"kindest/node:v1.27.3"}
REGISTRY_PORT=${REGISTRY_PORT:-"5000"}
REGISTRY_NAME=${REGISTRY_NAME:-"kind-registry"}
REGISTRY_IMAGE=${REGISTRY_IMAGE:-"registry:2"}
CLOUDSCAN_NGINX_NS=${CLOUDSCAN_NGINX_NS:-"ingress-nginx"}

# Check if kind cluster is already created
if [ "$(kind get clusters 2>/dev/null | grep -c '^kind$')" -eq 0 ]; then

  echo "$(date) creating KinD cluster with config:"
  cat config.yaml

  kind create cluster --config=config.yaml --image "$KIND_NODE_IMAGE"

  # Document the local registry
  cat <<-EOF  | kubectl apply -f -
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: local-registry-hosting
        namespace: kube-public
      data:
        localRegistryHosting.v1: |
          host: "localhost:${REGISTRY_PORT}"
          help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

  kubectl get nodes
  kubectl wait --for=condition="Ready" nodes --all --timeout="15m"

  kubectl apply -f ./metrics-server.yaml

  kubectl create ns "$CLOUDSCAN_NGINX_NS" || true

  helm install --namespace "$CLOUDSCAN_NGINX_NS" my-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --debug \
    --wait \
    --version 4.0.17 \
    -f nginx-values.yaml
else
  echo "KinD cluster is already created. Skipping cluster creation"
fi

running="$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    --network "kind" \
    -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" \
    "$REGISTRY_IMAGE"
fi

# Connect the registry to the kind network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
  docker network connect "kind" "${REGISTRY_NAME}"
fi

echo "KinD cluster setup complete!"