#!/bin/bash

# Mounts image file to local filesystem in ./root and ./boot if RAW (assumes EFI if type of image is raw)
# Note: You can run ./attach.sh filename.qcow2 to mount to the ./root then "chroot root" to run shell in the image and install apps, update, configure, etc.
# Run ./detach.sh when done

TYPE=qcow2
FILENAME=$1

Usage() {
  echo "Usage: ${0##*/} [filename]"
  exit 1
}

if [[ $FILENAME =~ "." ]]; then
  EXT=`echo $FILENAME | awk -F'.' '{print $2}'`
  echo Extension = $EXT
  if [[ -n $EXT ]]; then
    if [ $EXT == "img" ]; then
      TYPE="raw"
    elif [[ $EXT = "qcow2" || $EXT = "raw" || $EXT == "qcow" ]]; then
      TYPE=$EXT
    fi
    echo Type = $TYPE
  fi
else
  echo Detecting extension failed.
  exit 1
fi


if [ $# -ne 1 ]; then
  Usage
  exit 1
fi

sync
modprobe nbd
sleep 1
qemu-nbd -c /dev/nbd0 $1 --format=$TYPE
sleep 1
mkdir -p root boot
if [ $TYPE == "raw" ]; then
  mount /dev/nbd0p1 boot
  mount /dev/nbd0p3 root
else
  mount /dev/nbd0p1 root
fi
mount --bind /dev root/dev
mount --bind /sys root/sys
mount --bind /proc root/proc
mount --bind /dev/pts root/dev/pts
