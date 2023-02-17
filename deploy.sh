#!/bin/bash

# Launches vm

# Default if no args
GUEST="guest.qcow2"

[ ! -z $1 ] && GUEST=$1

[ ! -f $GUEST ] && echo "File not found!" && exit 1

# Remove any existing vm by this name...
virsh destroy $GUEST 2>/dev/null
virsh undefine $GUEST 2>/dev/null

cp $GUEST /var/lib/libvirt/images/

# Install and launch basic config
virt-install --name $GUEST --vcpus 1 --memory 1024 --os-variant generic --noautoconsole --console pty,target_type=serial --graphics none --accelerate --network network="default" --disk=/var/lib/libvirt/images/$GUEST --import
#  --import --disk=/var/ramdisk/guest1.qcow2 \

# Show in console
virt-manager
virsh console $GUEST
