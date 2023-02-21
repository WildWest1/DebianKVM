#!/bin/bash

# Uses virsh-install to deploy vms to default directory persistently (OVERWRITES EXISTING)

FILENAME=$1
VMHOME=/var/lib/libvirt/images/
VMPATH=$VMHOME$FILENAME

. common.sh

Usage() {
  echo "Usage: ${0##*/} [filename]"
  exit 1
}

GetVmFileType $FILENAME

if [ $# -ne 1 ]; then
  Usage
  exit 1
else
  if [ -f $VMPATH ]; then
    echo "Are you sure you want to remove $VMHOME$FILENAME (y)?"
    read RESULT
    if [[ $RESULT != "Y" && $RESULT != "y" ]]; then
      exit 1
    fi
  fi
  rm $VMPATH 2>/dev/null
  cp $FILENAME $VMHOME
  chown libvirt-qemu:libvirt-qemu $VMPATH
  chmod 600 $VMPATH

  # Delete existing instance
  virsh destroy $FILENAME 2>/dev/null
  virsh --connect qemu:///system undefine --nvram $FILENAME 2>/dev/null

  # CREATE NEW VM
  if [[ $TYPE == "qcow2" || $TYPE == "qcow" ]]; then
    # Assume this is a guest since it is a qcow type, which needs minimal hardware, and has no need for EFI firmware (boots to default bios)
    virt-install --name $FILENAME \
    --vcpus 1 \
    --memory 1024 \
    --os-variant generic \
    --disk $VMPATH,bus=virtio,format=$TYPE \
    --import \
    --noautoconsole \
    --console pty,target_type=serial \
    --graphics none \
    --accelerate \
    --network network="default" \

  elif [ $TYPE == "raw" ]; then
    # Assume this is a host since it is likely a raw type, which is probably meant to be used to make usb, so give it more hardware, and EFI firmware
    virt-install --name $FILENAME \
      --vcpus 4 \
      --memory 8192 \
      --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readonly=yes,loader.type=pflash \
      --os-variant generic \
      --disk $VMPATH,format=$TYPE \
      --import \
      --noautoconsole \
      --console pty,target_type=serial \
      --network network="default"
  fi
  # Launch console
  #virsh console $FILENAME
  echo
  echo "To list running vms use \"virsh list\", or to connect to the console of this vm now run:"
  echo "virsh console $FILENAME"
fi
