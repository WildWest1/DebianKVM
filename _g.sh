#!/bin/bash

# Do not remove these checks, you dont want your host bootloader altered do you?
# These lines insure this script will only run once inside guest vm
ischroot ; [ $? -ne 0 ] && echo "Warning: Do not run on host, this script should only run inside guest vm" && exit 1 || echo "Running in chroot" || echo "Starting setup script..."
cd /root
[ -f 0 ] && echo "This script can only be run once!" && exit 1 ; touch 0


#####***** RUN WITHIN IMAGE - CALLED BY SETUP SCRIPT *****#####
LANG=C.UTF-8

# UPDATE SOURCES
echo -e "deb http://deb.debian.org/debian bullseye main contrib non-free\ndeb http://deb.debian.org/debian bullseye-updates main contrib non-free\ndeb http://deb.debian.org/debian bullseye-backports main contrib non-free\ndeb http://security.debian.org/debian-security/ bullseye-security main contrib non-free" > /etc/apt/sources.list
apt update

# INSTALL KERNEL
apt install -y linux-image-amd64
# INSTALL APPS
apt install -y init iproute2 ifupdown nftables ssh iputils-ping sudo nano wget ncat dnsutils
# INSTALL GRUB2 BOOTLOADER
apt install -y grub2

# FSTAB AUTOMOUNT ROOTFS
root_uuid='UUID="'$(blkid -s UUID -o value /dev/nbd0p1)'"'
echo -e "# /etc/fstab: static file system information.\n# <file system> <mount point>   <type>  <options>       <dump>  <pass>\n$root_uuid / ext4 errors=remount-ro 0 1" > /etc/fstab
# NETWORK DHCP
echo -e "\n\nauto enp0s2\niface enp0s2 inet dhcp\n" >> /etc/network/interfaces

# CONFIGURE GRUB BOOTLOADER
grub-install /dev/nbd0
key=GRUB_CMDLINE_LINUX_DEFAULT && value='"console=tty0 console=ttyS0"' && sed -i "s|^\(${key}\s*=\s*\).*\$|\1${value}|" /etc/default/grub ; printf 'GRUB_TERMINAL="serial console"' >> /etc/default/grub
update-grub

### ENABLE SERVICES
ln -s /lib/systemd/system/nftables.service /etc/systemd/system/multi-user.target.wants/nftables.service

# Host fixes for production
cp config/common/sleep.conf /etc/systemd/
cp config/common/sshd_config /etc/ssh/
cp config/common/sysctl.conf /etc/

echo -e "password\npassword" | passwd
apt clean
apt autoremove
rm -rf /tmp/* ~/.bash_history
exit

#####***** EXIT CHROOT *****#####
