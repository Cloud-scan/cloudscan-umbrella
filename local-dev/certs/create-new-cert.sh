#!/usr/bin/env bash

set -euo pipefail

TLS_CERT_PATH=tls.crt
TLS_KEY_PATH=tls.key

echo "Generating self-signed TLS certificate for CloudScan..."

openssl req -x509 -nodes -days 730 \
  -newkey rsa:2048 \
  -keyout $TLS_KEY_PATH \
  -out $TLS_CERT_PATH \
  -config openssl-config.conf \
  -sha256

echo "TLS certificate generated successfully:"
echo "  Certificate: $TLS_CERT_PATH"
echo "  Private Key: $TLS_KEY_PATH"