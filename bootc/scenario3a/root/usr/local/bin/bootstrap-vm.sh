#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

VM="${1}"
if [ -d "/var/lib/libvirt/images/${VM}/" ]; then
  echo "VM ${VM} already exists. Please remove it first."
  exit 1
fi

temp_dir=$(mktemp -d)
cleanup() {
  local exit_code=$?
  rm -rf "$temp_dir"
  if [ $exit_code -ne 0 ]; then
    echo "An error occurred. Cleaning up..."
    virsh destroy "${VM}" || true
    virsh undefine "${VM}" --nvram || true
    rm -rf "/var/lib/libvirt/images/${VM}/"
  fi
}
trap cleanup EXIT

# Create a temporary directory to hold the VM image and copy the base image there
install -m 0710 -o root -g qemu --context=system_u:object_r:virt_image_t:s0 -d "$temp_dir"
install -m 0770 -o root -g qemu --context=system_u:object_r:virt_image_t:s0 "/usr/local/libvirt/images/${VM}/qcow2/disk.qcow2" "$temp_dir/root.qcow2"

# Inject the Flightctl configuration file (w/ enrollment certificates) into the VM image
# Note: The injected config file will be moved to the right place in the VM by a systemd override in the base image
if [ -f /etc/flightctl/config.yaml ]; then
  if [ -n "${FLIGHTCTL_LABELS_OVERRIDE:-}" ]; then
    echo "Overriding default labels with: ${FLIGHTCTL_LABELS_OVERRIDE}"
    yq e ". * { \"default-labels\": ${FLIGHTCTL_LABELS_OVERRIDE} }" /etc/flightctl/config.yaml > "$temp_dir/config.yaml"
  else
    cp /etc/flightctl/config.yaml "$temp_dir/config.yaml"
  fi
  guestfish --add "$temp_dir/root.qcow2" -m /dev/sda4 <<EOF
copy-in $temp_dir/config.yaml /ostree/deploy/default/var/lib/private/flightctl/
EOF
fi

# Inject the OSTree auth.json file into the VM image if it exists on the host
# Note: The injected config file will be moved to the right place in the VM by a systemd override in the base image
if [ -f /etc/ostree/auth.json ]; then
  guestfish --add "$temp_dir/root.qcow2" -m /dev/sda4 <<'EOF'
copy-in /etc/ostree/auth.json /ostree/deploy/default/var/lib/private/flightctl/
EOF
fi

# Copy the VM image to the libvirt images directory
install -m 0710 -o root -g qemu -Z -d "/var/lib/libvirt/images/${VM}"
install -m 0660 -o root -g qemu -Z "$temp_dir/root.qcow2" "/var/lib/libvirt/images/${VM}/root.qcow2"

# Create and start the VM using virt-install
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

echo "VM ${VM} has been created and started."
exit 0
