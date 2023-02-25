#!/bin/bash

# Mount any installation of linux filesystem directly for chroot, just like ./atach.sh does for image files
# Can use ./detach.sh to disconnect

. common.sh

Usage() {
  echo "Parameters required:"
  echo -e "\t- Path to physical disk (ex: /dev/sdb)"
  echo -e "\t- Firmare type: bios or efi (b or e)"
  exit 1
}

[ ! -b $1 ] && Usage
DIR=$1
[[ "$2" != "b" && "$2" != "e" ]] && Usage
FIRMWARE="BIOS"
[ "$2" == "e" ] && FIRMWARE="EFI"

umount ${DIR}1 >/dev/null 2>/tmp/error
[ $? -ne 0 ] && ErrorTest
umount ${DIR}3 >/dev/null 2>/tmp/error
[ $? -ne 0 ] && ErrorTest

echo -e "${ORANGE}Mounting ${DIR} for ${FIRMWARE}:${NONE}"

mkdir -p root

if [ "$FIRMWARE" == "EFI" ]; then
  mkdir -p boot
  mount ${DIR}1 boot >/dev/null 2>/tmp/error
  [ $? -ne 0 ] && ErrorTest
  mount ${DIR}3 root >/dev/null 2>/tmp/error
  [ $? -ne 0 ] && ErrorTest
else
  mount ${DIR}1 root >/dev/null 2>/tmp/error
  [ $? -ne 0 ] && ErrorTest
fi

echo "Binding.."
mount --bind /dev root/dev >/dev/null 2>/tmp/error
[ $? -ne 0 ] && ErrorTest
mount --bind /sys root/sys >/dev/null 2>/tmp/error
[ $? -ne 0 ] && ErrorTest
mount --bind /proc root/proc >/dev/null 2>/tmp/error
[ $? -ne 0 ] && ErrorTest
mount --bind /dev/pts root/dev/pts >/dev/null 2>/tmp/error
[ $? -ne 0 ] && ErrorTest

echo ; echo -e "${GREEN}COMPLETE!${NONE} Use \"chroot root\" and ./detach.sh when done." ; echo
