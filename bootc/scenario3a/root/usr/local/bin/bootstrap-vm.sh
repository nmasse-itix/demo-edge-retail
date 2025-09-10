#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

VM="${1}"

mkdir -p "/var/lib/libvirt/images/${VM}"
cp -a "/usr/local/libvirt/images/${VM}/qcow2/disk.qcow2" "/var/lib/libvirt/images/${VM}/root.qcow2"

# Inject the Flightctl configuration file (w/ enrollment certificates) into the VM image
if [ -f /etc/flightctl/config.yaml ]; then
  guestfish --add /var/lib/libvirt/images/${VM}/root.qcow2 -m /dev/sda4 <<'EOF'
copy-in /etc/flightctl/config.yaml /ostree/deploy/default/var/lib/flightctl/
EOF
fi

virt-install --name "${VM}" \
             --autostart \
             --cpu=host-passthrough \
             --vcpus=${DOMAIN_VCPUS} \
             --ram=${DOMAIN_RAM} \
             --os-variant=${DOMAIN_OS_VARIANT} \
             --disk=path=/var/lib/libvirt/images/${VM}/root.qcow2,bus=virtio,format=qcow2,size=${DOMAIN_DISK_SIZE} \
             --console=pty,target_type=virtio \
             --serial=pty \
             --graphics=none \
             --import \
             --network=network=default,mac=${DOMAIN_MAC_ADDRESS} \
             --noautoconsole
