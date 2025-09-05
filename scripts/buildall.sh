#!/bin/bash

set -Eeuo pipefail

if [[ "$UID" -ne 0 ]]; then
  echo "This command must be run as root!"
  exit 1
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

. "$PROJECT_DIR/config.env"

for dir in "$PROJECT_DIR"/{generic,scenario*}; do
  if [ -d "$dir" -a -f "$dir/Containerfile" ]; then
    export SCENARIO="${dir##*/}"
    TARGET_IMAGE="$(echo -n "$TARGET_IMAGE_TEMPLATE" | envsubst)"
    echo "Building container image $TARGET_IMAGE from $SCENARIO..."
    pushd "$dir" > /dev/null
    "$SCRIPT_DIR/build.sh" "$TARGET_IMAGE"
    popd > /dev/null
  fi
done
