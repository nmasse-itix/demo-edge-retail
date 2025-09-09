#!/bin/bash

set -Eeuo pipefail

if [[ "$UID" -ne 0 ]]; then
  echo "This command must be run as root!"
  exit 1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

. "$PROJECT_DIR/config.env"

function bootc_image_builder () {
  local config="$1"
  shift
  podman run --rm -it --privileged --pull=newer --security-opt label=type:unconfined_t -v "$config:/$(basename $config):ro" \
             -v $PWD/root/usr/local/libvirt/images/nextcloud:/output -v /var/lib/containers/storage:/var/lib/containers/storage \
             registry.redhat.io/rhel10/bootc-image-builder:latest --config "/$(basename $config)" "$@"
}

BOOTC_IMAGE="$(echo -n "$TARGET_IMAGE_TEMPLATE" | SCENARIO=scenario1 envsubst)"
echo "Building qcow2 from $BOOTC_IMAGE..."
bootc_image_builder "$PWD/config.toml" --type qcow2 "$BOOTC_IMAGE"

