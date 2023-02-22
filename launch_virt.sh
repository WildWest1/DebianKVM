#!/bin/bash

# Creates a vm and registers it with virsh using virt-install
# VIRT-INSTALL is good for testing quickly but use the more advance virsh create or virsh define along with xml configuration files for ultimate setup!

GUEST="guest.qcow2"

[ ! -z $1 ] && GUEST=$1

[ ! -f $GUEST ] && echo "File not found!" && exit 1

virsh net-start default >/dev/null 2>&1

# Remove any existing vm by this name...
virsh destroy $GUEST >/dev/null 2>&1
virsh undefine $GUEST >/dev/null 2>&1

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
