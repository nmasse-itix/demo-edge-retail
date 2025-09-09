#!/bin/bash

set -Eeuo pipefail

if [[ "$UID" -ne 0 ]]; then
  echo "This command must be run as root!"
  exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# This function iterates over all files contained in the directory passed as the first argument
# and install them to the directory passed as the second argument, using the install command.
# It preserves the directory structure of the source directory.
# The remaining arguments are passed to the install command.
function install_files() {
    local src_dir="$1"
    local dest_dir="$2"
    shift 2

    find "$src_dir" -type f | while read -r file; do
        local relative_path="${file#$src_dir/}"
        local dest_path="$dest_dir/$relative_path"

        install "$@" "$file" "$dest_path"
    done
}

# Same but for directories
function install_directories() {
    local src_dir="$1"
    local dest_dir="$2"
    shift 2

    find "$src_dir" -type d | while read -r dir; do
        local relative_path="${dir#$src_dir}"
        relative_path="${relative_path#/}" # Remove leading slash if present
        local dest_path="$dest_dir/$relative_path"

        install "$@" -d "$dest_path"
    done
}

# This function templates a kickstart file by replacing placeholders with actual values.
# The templates are located in the www/ks directory.
# The output files are written to /var/www/ks.
# The placeholders are in the format expected by envsubst.
# For each template file, seven versions are created: base + scenario{1,2,3,4,5,6}.
# The output files are named as /var/www/ks/<template>/<scenario>.ks.
function template_kickstart_files() {
    local templates_dir="${SCRIPT_DIR}/www/ks"
    local output_dir="/var/www/ks"
    local scenarios=("base" "scenario1" "scenario2" "scenario3" "scenario4" "scenario5" "scenario6")

    for template in "$templates_dir"/*.ks; do
        local template_name="$(basename "$template" .ks)"

        for scenario in "${scenarios[@]}"; do
            install -d -m 0755 -o root -g root -Z "$output_dir/${template_name}"
            local output_file="$output_dir/${template_name}/${scenario}.ks"
            echo "Templating $template_name to $output_file"
            (
                export SCENARIO_NAME="$scenario"
                if [ -f "auth.json" ]; then
                    export AUTH_JSON_CONTENT="$(cat auth.json)"
                fi
                if [ -f "config.yaml" ]; then
                    export FLIGHTCTL_CONFIG_CONTENT="$(cat config.yaml)"
                fi
                envsubst < "$template" > "/tmp/tmp.$$.ks"
            )
            install -m 0644 -o root -g root "/tmp/tmp.$$.ks" "$output_file"
        done
    done
}

echo "Installing PXE boot files..."
rm -rf "/var/lib/tftpboot"
install_directories "${SCRIPT_DIR}/tftpboot" "/var/lib/tftpboot" -m 755 -o dnsmasq -g dnsmasq -Z
install_files "${SCRIPT_DIR}/tftpboot" "/var/lib/tftpboot" -m 644 -o dnsmasq -g dnsmasq -Z
install -m 0644 -o dnsmasq -g dnsmasq /usr/share/ipxe/{undionly.kpxe,ipxe-snponly-x86_64.efi} /var/lib/tftpboot/
install -m 0644 -o dnsmasq -g dnsmasq /usr/share/ipxe/arm64-efi/snponly.efi /var/lib/tftpboot/ipxe-snponly-arm64.efi
restorecon -RF "/var/lib/tftpboot"

echo "Installing nginx files..."
rm -rf "/var/www/ks"
install -d -m 0755 -o root -g root /var/www/repo/rhel{9,10}/{x86_64,arm64}/ /var/www/ks/
template_kickstart_files
restorecon -RF "/var/www"

echo "Configuring dnsmasq..."
install -m 0644 -o root -g root -Z "${SCRIPT_DIR}/config/dnsmasq/dnsmasq.conf" /etc/dnsmasq.d/tftp.conf
systemctl enable dnsmasq.service
systemctl restart dnsmasq.service

echo "Configuring nginx..."
install -m 0644 -o root -g root -Z "${SCRIPT_DIR}/config/nginx/nginx.conf" /etc/nginx/nginx.conf
systemctl enable nginx.service
systemctl restart nginx.service
