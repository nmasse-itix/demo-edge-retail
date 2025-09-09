# PXE Boot configuration

## DHCP configuration

```ini
##
## Boot PXE for Edge devices
##

# Architecture identifier comes from https://www.iana.org/assignments/dhcpv6-parameters/dhcpv6-parameters.xhtml#processor-architecture
dhcp-match=set:bios,option:client-arch,0
dhcp-match=set:efix32,option:client-arch,6
dhcp-match=set:efix64,option:client-arch,7
dhcp-match=set:efix64,option:client-arch,9
dhcp-match=set:efiarm64,option:client-arch,11
dhcp-match=set:ipxe,option:user-class,iPXE

# See https://ipxe.org/howto/chainloading
dhcp-boot=tag:pxe,tag:bios,tag:!ipxe,undionly.kpxe,,192.168.2.41
dhcp-boot=tag:pxe,tag:efix64,tag:!ipxe,ipxe-snponly-x86_64.efi,,192.168.2.41
dhcp-boot=tag:pxe,tag:efiarm64,tag:!ipxe,ipxe-snponly-arm64.efi,,192.168.2.41
dhcp-boot=tag:pxe,tag:ipxe,boot.ipxe,,192.168.2.41

##
## Dell Optiplex 7000 Micro  
##
dhcp-host=set:vlan2,set:pxe,00:be:43:ec:56:19,192.168.2.73,[::49],24h
host-record=optiplex-7000.itix.fr,192.168.2.73,[::49],24h

##
## Adlink DLAP 4001 SMD
##
dhcp-host=set:vlan2,set:pxe,00:19:0f:44:03:91,192.168.2.75,[::4b],24h
host-record=adlink-dlap-4001.itix.fr,192.168.2.75,[::4b],24h
```

## DVD content in `/var/www/repo`

```sh
sudo mount ~/Downloads/rhel-9.6-x86_64-dvd.iso /mnt -o loop,ro
rsync -av /mnt/ nicolas@edge-infra.itix.fr:/var/www/repo/rhel9/x86_64/
sudo umount /mnt
sudo mount ~/Downloads/rhel-9.6-aarch64-dvd.iso /mnt -o loop,ro
rsync -av /mnt/ nicolas@edge-infra.itix.fr:/var/www/repo/rhel9/arm64/
sudo umount /mnt
sudo mount ~/Downloads/rhel-10.0-x86_64-dvd.iso /mnt -o loop,ro
rsync -av /mnt/ nicolas@edge-infra.itix.fr:/var/www/repo/rhel10/x86_64/
sudo umount /mnt
sudo mount ~/Downloads/rhel-10.0-aarch64-dvd.iso /mnt -o loop,ro
rsync -av /mnt/ nicolas@edge-infra.itix.fr:/var/www/repo/rhel10/arm64/
sudo umount /mnt
```

## Flightctl configuration file

```sh
flightctl certificate request --signer=enrollment --expiration=365d --output=embedded > config.yaml
```

## Registry token

```sh
export REGISTRY_AUTH_FILE="$PROJECT_DIR/auth.json"
podman login registry.redhat.io
podman login my.registry.example
```

