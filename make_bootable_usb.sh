#!/bin/bash

# CREATE BOOTABLE USB FLASH DRIVE FROM IMAGE
# Detaches any mounts or auto mounts with warnings
# If image is qcow/2 type, converts to raw

FILENAME=$1
TYPE=raw

. common.sh

echo -e $GREEN
echo "***********************************************************"
echo "The script will make a bootable USB drive out of a vm image"
echo "Your usb drive must be /dev/sdb (automatically checks)"
echo "To manually verify: Run lsblk when plugged/unplugged"
echo "This script will auto unmount any mount points on sdb"
echo "***********************************************************"
echo -ne $NONE

Sanity() {
  # SOURCE FILE EXISTS
  [ ! -f $FILENAME ] && echo -e "${LTRED}-->Image file not found!" && echo && echo -e $NONE && exit 1
  # DESTINATION (sdb) IS NOT ROOT FS
  ROOTDRIVE=$(mount|grep ' / '|cut -d' ' -f 1 | sed 's/.$//')
  [ "$ROOTDRIVE" == "/dev/sdb" ] && echo -e "${LTRED}-->You root drive is sdb, cannot continue" && echo -e $NONE && exit 1
}

function UsbExists {
  if [ ! -e /dev/sdb ]; then
    echo "Flash drive not found in /dev/sdb"
    echo "Please insert USB drive now..."
    echo "CTRL+C to break"
    read
    return 1
  else
    return 0
  fi
}

Usage() {
  echo "WARNING: This will overwrite the drive specified."
  echo "Usage: ${0##*/} [filename]"
  exit 1
}

UniqueFile() {
    if [ -f ${NAME}.img ]; then
        echo -n The file ${NAME}.img exits, generating random filename:
        NAME=$(openssl rand -hex 5)
        echo " ${NAME}.img"
    fi
}

Sanity

# Get image type
if [[ $FILENAME =~ "." ]]; then
  NAME=$(echo $FILENAME | awk -F'.' '{print $1}')
  EXT=$(echo $FILENAME | awk -F'.' '{print $2}')
  if [ -n "$EXT" ]; then
    if [ $EXT == "img" ]; then
      TYPE="raw"
    elif [[ $EXT = "qcow2" || $EXT = "raw" || $EXT == "qcow" ]]; then
      TYPE=$EXT
    fi
  fi
else
    Usage
fi

# Check if sdb exists
while true
do
  UsbExists
  [ $? -eq 0 ] && break
  sleep 1
done

function IsYes {
  if [[ "$1" != "yes" && "$1" != "YES" ]]; then
    echo "You typed $1, try again, or CTRL+C to cancel."
    return 1;
  else
    return 0;
  fi
}

# Drive exists
echo Flash drive found in /dev/sdb!
PARTS=$(blkid | grep sdb | awk '{ print $1 }' | cut -c 1-9)
if [ -n "$PARTS" ]; then
  echo Flash drive has partitions: $PARTS
  while true
  do
    echo "Type [YES] if you are sure you want to *ERASE* /dev/sdb?"
    read REPLY
    IsYes "$REPLY"
    [ $? -eq 0 ] && break || sleep 1
  done
  MOUNTS=$(mount | grep sdb | awk '{ print $1 }')
  for USB in $MOUNTS ; do
    echo Unmounting ${USB}...
    $(umount $USB)
    if [ $? -ne 0 ]; then
      echo "Error: USB could not be unmounted."
      exit 1
    fi
  done
fi

# Convert?
if [[ $TYPE == "qcow2" || $TYPE == "qcow" ]]; then
  UniqueFile
  qemu-img convert -f $TYPE -O raw $FILENAME ${NAME}.img
  if [ $? -ne 0 ]; then
    echo Error: Could not convert qcow to raw format.
    exit 1
  fi
fi

# XXX: Qemu converter was unreliable and no progress, disabled for now
#echo Writing to flash drive, there will be no status, be patient...
#qemu-img dd if=$FILENAME of=/dev/sdb

#echo Begin copying...
dd if=$FILENAME of=/dev/sdb bs=4M status=progress oflag=nocache,sync conv=fsync
#dd if=$FILENAME of=/dev/sdb status=progress
sync
[ $? -eq 0 ] && echo "Success!" && exit 0 || echo "Failed." && echo 1
