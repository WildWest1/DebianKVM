#!/bin/bash

# Creates a vm and registers it with virsh using virt-install
# VIRT-INSTALL is good for testing quickly but use the more advance virsh create or virsh define along with xml configuration files for ultimate setup!

FILENAME=$1

. ./common.sh

Usage() {
  echo "Usage: ${0##*/} [filename]"
  exit 1
}

if [[ $# -ne 1 ]]; then
  Usage
fi

[ ! -z $1 ] && GUEST=$1

[ ! -f $FILENAME ] && echo "File not found!" && exit 1

virsh net-start default >/dev/null 2>&1

# Remove any existing vm by this name...
virsh destroy $FILENAME >/dev/null 2>&1
virsh undefine $FILENAME >/dev/null 2>&1

cp $FILENAME /var/lib/libvirt/images/

GetVmFileType $FILENAME
[ $? == 1 ] && echo "Error, wrong extension" && exit 1

BIORPARAM=
[ $TYPE == "raw" ] && BIOSPARAM="--boot uefi"

# Install and launch basic config
virt-install --name $FILENAME --vcpus 1 --memory 1024 --os-variant generic --console pty,target_type=serial --accelerate --network network="default" --disk=/var/lib/libvirt/images/$FILENAME --import $BIOSPARAM \
  --noautoconsole --graphics none   # Comment this line to run GUI (vs serial mode only)

# Show in console
echo
echo "OPTIONS:"
echo -e "  To view guest vm console RUN: \"${YELLOW}virsh console $FILENAME${NONE}\""
echo -e "  You can run \"${YELLOW}virt-manager\"${NONE} if KDE GUI is installed"
echo
