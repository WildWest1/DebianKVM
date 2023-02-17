#!/bin/bash

# Defaults if no params
FILENAME="guest.qcow2"
SIZE=2	# 2GB is minimum required
TYPE="qcow2"
SILENT=0

. common.sh

[ ! -z $2 ] && SILENT=1		# NO PROMPTS IF RAN WITH PARAMS

Usage() {
  echo -e $WHITE
  echo "Usage: ${0##*/} [name.qcow2 or name.raw or name.img] [int disk size (G)]"
  echo -e $NONE
  exit 1
}

if [ $# -eq 2 ]; then
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

if [ $SILENT -eq 0 ]; then
	# This script can be safely run repeatedly. The host is not modified other than installing KVM tools.
	echo -e $GREEN
	echo "***********************Debian VM setup script***********************"
	echo -e "Create: $WHITE$FILENAME$GREEN of size $WHITE${SIZE}GB$GREEN - ./setup.sh file.qcow2 10 will make 10GB"
	echo -e $NONE
	read -p "Install KVM and utils on this host, then build a new vm? (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] && echo || exit 0
	echo
fi

# SETUP HOST AS KVM SERVER
apt update
[ $? -ne 0 ] && echo "Unable to update apt" && exit 1
apt install -y systemd parallel rsync pciutils usbutils
[ $? -ne 0 ] &&	echo "Failed to install apps, no internet?" && exit 1

# INSTALL KVM
apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils virtinst libvirt-daemon libguestfs-tools virt-manager
[ $? -ne 0 ] && echo "Failed to install KVM, no internet?" && exit 1


# First detach and remove any existing image file by this name
echo -e "${RED}Checking for existing file and removing if found...${RED}"
if [ -f "$FILENAME" ]; then
  read -p "Existing image found, do you want to delete (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] && ./detach.sh && rm $FILENAME || exit 1
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
[ "$TYPE" == "raw" ] && FILE="_h.sh"
cp ${FILE} root/root/ && chroot root /root/${FILE}

if [ $SILENT -eq 0 ]; then
  ./detach.sh && echo "Complete!"
  echo -e $GREEN
  echo "***********************Debian VM setup script***********************"
  echo -e $NONE
  read -p "Deploy VM and show in console [runs deploy.sh $FILENAME]? (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] && echo "Deploying..." && ./deploy.sh
fi
echo -e $GREEN
echo "Done!"
echo -e $NONE
exit 0
