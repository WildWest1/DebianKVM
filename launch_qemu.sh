#!/bin/bash

# This is for rapid gui testing only...
# USE DEPLOY.SH INSTEAD - Qemu launched vms not register with virsh

FILENAME=$1
TYPE=qcow2

. ./common.sh

Usage() {
  echo "Usage: ${0##*/} [filename]"
  exit 1
}

if [[ $# -ne 1 ]]; then
  Usage
fi

GetVmFileType $FILENAME
[ $? == 1 ] && echo "Error, wrong extension" && exit 1

# Quick launch (GUI)
BIOSPARAM=
[ $TYPE == "raw" ] && BIOSPARAM="-bios /usr/share/ovmf/OVMF.fd"
qemu-system-x86_64 -name $FILENAME -M q35 -drive file=$FILENAME,format=$TYPE -m 1024 -smp 1 -machine accel=kvm -cpu kvm64 $BIOSPARAM &
