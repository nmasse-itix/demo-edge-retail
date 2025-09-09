##
## Environment setup
##

# Install mode: text (interactive installs) or cmdline (unattended installs)
text

# French keyboard layout
keyboard --vckeymap=fr --xlayouts='fr'

# English i18n
lang en_US.UTF-8 --addsupport fr_FR.UTF-8

# Accept the EULA
eula --agreed

# Which action to perform after install: poweroff or reboot
reboot

# Timezone is GMT
timezone Etc/GMT --utc

##
## network configuration
##

# No network configuration here since Anaconda does it automatically.

##
## partitioning
##

# Install on /dev/sda
ignoredisk --only-use=sda

# Clear the target disk
zerombr

# Remove existing partitions
clearpart --all --initlabel

# Automatically create partitions required by hardware platform
reqpart --add-boot

# Create a root and a /var partition
part / --fstype xfs --size=1 --grow --asprimary --label=root

##
## Pre-installation
##

%pre --log=/tmp/pre-install.log --erroronfail
cat > /etc/ostree/auth.json << 'EOF'
${AUTH_JSON_CONTENT}
EOF
chmod 0600 /etc/ostree/auth.json
%end

##
## Installation
##

rootpw --lock
ostreecontainer --url="edge-registry.itix.fr/demo-edge-retail/${SCENARIO_NAME}:latest" --transport=registry --no-signature-verification

##
## Post-installation
##

%post --log=/var/log/anaconda/post-install.log --erroronfail

set -Eeuo pipefail

# Inject flightctl initial configuration
cat > /etc/flightctl/config.yaml << 'EOF'
${FLIGHTCTL_CONFIG_CONTENT}
EOF
chmod 600 /etc/flightctl/config.yaml

cat > /etc/ostree/auth.json << 'EOF'
${AUTH_JSON_CONTENT}
EOF
chmod 0600 /etc/ostree/auth.json

%end
