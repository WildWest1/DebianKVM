#!/bin/bash

# Launches vm

# Default if no args
GUEST="guest.qcow2"

[ ! -z $1 ] && GUEST=$1

[ ! -f $GUEST ] && echo "File not found!" && exit 1

virsh net-start default

# Remove any existing vm by this name...
virsh destroy $GUEST 2>/dev/null
virsh undefine $GUEST 2>/dev/null

cp $GUEST /var/lib/libvirt/images/

# Install and launch basic config
virt-install --name $GUEST --vcpus 1 --memory 1024 --os-variant generic --noautoconsole --console pty,target_type=serial --graphics none --accelerate --network network="default" --disk=/var/lib/libvirt/images/$GUEST --import

# Show in console
echo -e $GREEN
echo -e "To view guest vm console RUN: \"${YELLLOW}virsh console $GUEST${NONE}\""
echo "Rename guest.qcow2 and deploy as many vms as you want!"
echo -e "To see all guests RUN: \"${YELLOW}virsh list --all${NONE}\""
echo -e "Run \"${YELLOW}. ./virshaliases.sh${NONE}\" or \"${YELLOW}cat virshaliases${NONE}\" to see virsh options"
echo -e $NONE
