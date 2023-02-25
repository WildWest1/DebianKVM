#!/bin/bash

# THIS FILE SETS UP A BASE IMAGE, AND THEN BUILDS A HOST OR GUEST BY THE NAME AND SIZE SPECIFIED
# RUN THIS IF YOU WANT TO CREATE CUSTOM IMAGES, OTHERWISE USE make host OR make guest

# Defaults if no params
FILENAME="guest.qcow2"
SIZE=2	# 2GB is minimum required
TYPE="qcow2"
DETACH=1

. common.sh

[ ! -z $3 ] && DETACH=0

Usage() {
  echo -e $WHITE
  echo "Usage: ${0##*/} [name.qcow2 or name.raw or name.img] [int disk size (G)]"
  echo -e $NONE
  exit 1
}

if [ $# -ge 2 ]; then
  if [ $2 -gt 0 ]; then
    SIZE=$2
  else
    Usage
  fi
fi
if [ ! -z $1 ]; then
  FILENAME=$1
fi
if [[ "$FILENAME" =~ "." ]]; then
  EXT=$(echo "$FILENAME" | awk -F'.' '{print $2}')
  if [[ -n $EXT ]]; then
    if [ $EXT == "img" ]; then
      TYPE="raw"
    elif [[ $EXT = "qcow2" || $EXT = "raw" || $EXT == "qcow" ]]; then
      TYPE=$EXT
    fi
  fi
fi

# First detach and remove any existing image file by this name
echo -e "Checking for existing file and removing if found..."
if [ -f "$FILENAME" ]; then
  read -p "Existing image found, do you want to delete? (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] && rm $FILENAME || exit 1
fi

echo -e "--------------------\nFile: ${FILENAME}\nType: ${TYPE}\nSize: ${SIZE}\n--------------------\n"

echo "Creating VM image file..."
qemu-img create -f ${TYPE} ${FILENAME} ${SIZE}G
[ $? -ne 0 ] && echo "Failed to create $FILENAME" && exit 1 || echo "Created image..."
./detach.sh
sync
modprobe nbd
qemu-nbd  --connect=/dev/nbd0 ${FILENAME} --format=${TYPE}
[ $? -ne 0 ] && echo "Failed to mount $FILENAME" && exit 1 || echo "Mounted image..."
partprobe /dev/nbd0
echo "Partitioning..."
if [[ "$TYPE" == "qcow" || "$TYPE" == "qcow2" ]]; then
  fdisk /dev/nbd0 << EOF
n
p
1


a
w
EOF
  echo "Formatting..."
  mkfs.ext4 -L root /dev/nbd0p1
  [ $? -ne 0 ] && echo "Failed to format" && exit 1 || echo "Formatted"
  mkdir -p root
  echo "Mounting filesystem..."
  mount /dev/nbd0p1 root
  [ $? -ne 0 ] && echo "Failed to mount filesystem" && exit 1 || echo "Mounted filesystem"
else
  echo "Creating partitions..."
  parted -s -a optimal -- /dev/nbd0 \
    mklabel gpt \
    mkpart primary fat32 1MiB 300MiB \
    mkpart primary linux-swap 300MiB 1GiB \
    mkpart primary ext4 1GiB -0 \
    name 1 uefi \
    name 2 swap \
    name 3 root \
    set 1 esp on
  sleep 1
  echo "Formatting..."
  mkfs.fat -F 32 -n EFI /dev/nbd0p1
  mkswap -L swap /dev/nbd0p2
  mkfs.ext4 -L root /dev/nbd0p3
  [ $? -ne 0 ] && echo "Failed to format" && exit 1 || echo "Formatted"
  echo "Mounting filesystem..."
  mkdir -p root boot
  mount /dev/nbd0p1 boot
  mount /dev/nbd0p3 root
  [ $? -ne 0 ] && echo "Failed to mount filesystem" && exit 1 || echo "Mounted filesystem"
fi

debootstrap --variant=minbase --arch amd64 stable root http://deb.debian.org/debian/

# Wasn't fully mounted bc filesystem didnt exist, remount fully
./detach.sh
./attach.sh $FILENAME
[ $? -ne 0 ] && echo "Failed to mount: $FILENAME" && exit 1

# Copy scripts and launch inside chroot
FILE="_g.sh"
if [ "$TYPE" == "raw" ]; then
  FILE="_h.sh"
  # Add KVM hosting scripts and files
  cp *.sh root/root/
  cp -r config root/root/
}
cp ${FILE} root/root/ && chroot root /root/${FILE}

# Disable sleep, enable SSH server, and enable forwarding
cp config/common/sleep.conf /etc/systemd/
cp config/common/sshd_config /etc/ssh/
cp config/common/sysctl.conf /etc/

[ $DETACH -eq 1 ] && ./detach.sh

echo -e $GREEN
echo "Done!"
echo -e $NONE
exit 0
