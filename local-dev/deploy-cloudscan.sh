#!/usr/bin/env bash

set -xv
set -euo pipefail

source ./pre-cloudscan-req.sh "$@"

pushd cloudscan
  ./build-values.sh "$@"
  ./deploy.sh "$@"
popd

./post-cloudscan-req.sh "$@"