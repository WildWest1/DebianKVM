#!/bin/bash

# Do not remove these checks, you dont want your host bootloader altered do you?
# These lines insure this script will only run once inside guest vm
ischroot ; [ $? -ne 0 ] && echo "Warning: Do not run on host, this script should only run inside guest vm" && exit 1 || echo "Running in chroot" && echo "Starting setup script..."
cd /root
[ -f 0 ] && echo "This script can only be run once!" && exit 1 ; touch 0

LANG=C.UTF-8
echo "host" > /etc/hostname

swap_uuid="$(blkid | grep '^/dev/nbd0' | grep ' LABEL="swap" ' | grep -o ' UUID="[^"]\+"' | sed -e 's/^ //' )"
root_uuid="$(blkid | grep '^/dev/nbd0' | grep ' LABEL="root" ' | grep -o ' UUID="[^"]\+"' | sed -e 's/^ //' )"
efi_uuid="$(blkid | grep '^/dev/nbd0' | grep ' LABEL="EFI" ' | grep -o ' UUID="[^"]\+"' | sed -e 's/^ //' )"

echo -e "# /etc/fstab: static file system information.
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
$root_uuid / ext4 errors=remount-ro 0 1
$efi_uuid /boot/efi vfat defaults 0 1\n
tmpfs /var/ramdisk tmpfs rw,nodev,nosuid,size=5G" > /etc/fstab

mkdir -p /var/ramdisk
[[ -d /boot/efi ]] || mkdir /boot/efi
mount -a

# DEBIAN
echo "deb http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian bullseye-updates main contrib non-free
deb http://deb.debian.org/debian bullseye-backports main contrib non-free
deb http://security.debian.org/debian-security/ bullseye-security main contrib non-free" > /etc/apt/sources.list

apt update

apt install -y linux-image-amd64 systemd wget sudo nano net-tools iproute2 nftables dnsutils ifupdown openssh-server ssh inetutils-ping ncat parallel rsync intel-microcode pciutils usbutils build-essential lsof

# INSTALL KVM
apt install -y qemu-system-x86 libvirt-daemon-system libvirt-clients bridge-utils virtinst libvirt-daemon libguestfs-tools

#echo -e "\n\nauto enp1s0\nallow-hotplug enp1s0\niface enp1s0 inet static\n  address 192.168.0.200/24\n  gateway 192.168.0.1" >> /etc/network/interfaces.d/ensp1s0

### ENABLE SERVICES
ln -s /lib/systemd/system/nftables.service /etc/systemd/system/multi-user.target.wants/nftables.service
ln -s /lib/systemd/system/serial-getty@ttyS0.service /etc/systemd/system/multi-user.target.wants/serial-getty@ttyS0.service

echo -e "password\npassword" | passwd

# GRUB BOOTLOADER FOR UEFI:
apt install -y grub-efi-amd64 efibootmgr efivar
# enable grub console
key=GRUB_CMDLINE_LINUX_DEFAULT
value='"console=tty0 console=ttyS0"'
sed -i "s|^\(${key}\s*=\s*\).*\$|\1${value}|" /etc/default/grub
printf 'GRUB_TERMINAL="serial console"' >> /etc/default/grub
# INSTALL GRUB
mkdir -p /boot/efi/EFI/BOOT
grub-install --target=x86_64-efi
update-grub
cp /boot/efi/EFI/debian/fbx64.efi /boot/efi/EFI/BOOT/bootx64.efi

# Host fixes for production
cp config/common/sleep.conf /etc/systemd/
cp config/common/sshd_config /etc/ssh/
cp config/common/sysctl.conf /etc/

apt clean
apt autoremove
rm -rf /tmp/* ~/.bash_history
exit
