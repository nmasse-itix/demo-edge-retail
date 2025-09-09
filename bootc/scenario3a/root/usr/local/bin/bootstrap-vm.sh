#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

VM="${1}"

cp -a "/usr/local/libvirt/images/nextcloud/qcow2/disk.qcow2" "/var/lib/libvirt/images/${VM}/root.qcow2"

virt-install --name "${VM}" \
             --autostart \
             --cpu=host-passthrough \
             --vcpus=${DOMAIN_VCPUS} \
             --ram=${DOMAIN_RAM} \
             --os-variant=${DOMAIN_OS_VARIANT} \
             --disk=path=/var/lib/libvirt/images/${VM}/root.qcow2,bus=virtio,format=qcow2,size=${DOMAIN_DISK_SIZE}G \
             --console=pty,target_type=virtio \
             --serial=pty \
             --graphics=none \
             --import \
             --network=network=bridged,mac=${DOMAIN_MAC_ADDRESS}
