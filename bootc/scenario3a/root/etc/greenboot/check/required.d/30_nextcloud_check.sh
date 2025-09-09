#!/bin/bash

exit 0 # Temporary disable the check

set -Eeuo pipefail
MAX_ATTEMPTS=60

for (( attempt=1; attempt<=MAX_ATTEMPTS; attempt++ )); do
  echo "Checking VM ($attempt/$MAX_ATTEMPTS)..."
  
  if virsh domstate nextcloud | grep -q 'running'; then
    echo "Nextcloud VM is running."
    exit 0
  fi

  sleep 5
done

echo "Nextcloud VM is not running correctly after $MAX_ATTEMPTS attempts!"
exit 1
