#!/bin/bash

# SETUP THIS HOST AS KVM SERVER (OPTIONAL, HOST.IMG HAS KVM INSTALLED, USETHIS TO INSTALL KVM LOCALLY)
apt update
[ $? -ne 0 ] && echo "Unable to update apt" && exit 1
apt install -y systemd parallel rsync pciutils usbutils
[ $? -ne 0 ] &&	echo "Failed to install apps, no internet?" && exit 1
# INSTALL KVM
apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils virtinst libvirt-daemon libguestfs-tools virt-manager
[ $? -ne 0 ] && echo "Failed to install KVM, no internet?" && exit 1
apt install -y build-essential git 
