#!/usr/bin/env bash

set -xv
set -euo pipefail

pushd ../../chart-versions
  IMAGE_VERSIONS_VALUES=$(cat <<END

orchestrator:
  image:
    tag: "$(cat cloudscan-orchestrator.version)"

apiGateway:
  image:
    tag: "$(cat cloudscan-api-gateway.version)"

storage:
  image:
    tag: "$(cat cloudscan-storage.version)"

websocket:
  image:
    tag: "$(cat cloudscan-websocket.version)"

ui:
  image:
    tag: "$(cat cloudscan-ui.version)"

runner:
  image:
    tag: "$(cat cloudscan-runner.version)"

END
  ) ;
popd

echo "image versions values:"
echo "$IMAGE_VERSIONS_VALUES"

echo "$IMAGE_VERSIONS_VALUES" > ./image-versions-values.yaml