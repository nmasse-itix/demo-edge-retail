#!/bin/bash

set -Eeuo pipefail
declare -a container_state=()
MAX_ATTEMPTS=60

for (( attempt=1; attempt<=MAX_ATTEMPTS; attempt++ )); do
  echo "Checking Odoo deployment ($attempt/$MAX_ATTEMPTS)..."
  
  state=1
  for container in odoo-db odoo-app; do
    container_state=( $( ( podman inspect "$container" || true ) | jq -r '.[0].State.Status // "unknown", .[0].State.Health.Status // "unknown"') )
    echo "Container $container has state ${container_state[0]} and its health is ${container_state[1]}!"
    if [[ "${container_state[0]}-${container_state[1]}" != "running-healthy" ]]; then
      state=0
    fi
  done

  if [[ $state -eq 1 ]]; then
    echo "Odoo deployment is up and running!"
    exit 0
  fi

  sleep 5
done

echo "Odoo deployment is not running correctly after $MAX_ATTEMPTS attempts!"
exit 1
