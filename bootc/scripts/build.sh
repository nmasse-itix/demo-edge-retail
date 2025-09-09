#!/bin/bash

set -Eeuo pipefail

if [[ "$UID" -ne 0 ]]; then
  echo "This command must be run as root!"
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target-image>"
  exit 1
fi

TARGET_IMAGE="$1"
OCI_REGISTRY="${TARGET_IMAGE%%/*}"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$PROJECT_DIR/signing-key.pass" ]; then
  openssl rand -base64 30 > "$PROJECT_DIR/signing-key.pass"
  chmod 600 "$PROJECT_DIR/signing-key.pass"
fi

if [ ! -f "$PROJECT_DIR/signing-key.pub" ]; then
  skopeo generate-sigstore-key --output-prefix "$PROJECT_DIR/signing-key" --passphrase-file "$PROJECT_DIR/signing-key.pass"
fi

if [ ! -f "/etc/containers/registries.d/${OCI_REGISTRY}.yaml" ]; then
  tee "/etc/containers/registries.d/${OCI_REGISTRY}.yaml" > /dev/null <<EOF
docker:
  ${OCI_REGISTRY}:
    use-sigstore-attachments: true
EOF
fi

export REGISTRY_AUTH_FILE="$PROJECT_DIR/auth.json"
if [ ! -f "$REGISTRY_AUTH_FILE" ]; then
  echo "Please enter your credentials for ${OCI_REGISTRY}:"
  podman login "${OCI_REGISTRY}"

  echo "Please enter your credentials for registry.redhat.io:"
  podman login registry.redhat.io
fi

if [ -x "$PWD/custom.sh" ]; then
  echo "Running custom.sh..."
  "$PWD/custom.sh"
fi

podman build --no-cache -t "${TARGET_IMAGE}" .
podman push --sign-by-sigstore-private-key "$PROJECT_DIR/signing-key.private" --sign-passphrase-file "$PROJECT_DIR/signing-key.pass" "${TARGET_IMAGE}"
