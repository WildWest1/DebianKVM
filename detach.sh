#!/bin/sh

# Detaches from mounted image
echo Detaching from mounted image...
umount -l root/boot/efi 2>/dev/null
umount -l boot 2>/dev/null
umount -l root/dev/pts 2>/dev/null
umount -l root/dev 2>/dev/null
umount -l root/proc 2>/dev/null
umount -l root/sys 2>/dev/null
umount -l root/var/ramdisk 2>/dev/null
umount -l root 2>/dev/null
ERROR=$(qemu-nbd -d /dev/nbd0 >/dev/null 2>&1)
[ $? ] && echo "Detached!" || echo $ERROR
rmdir root 2>/dev/null
rmdir boot 2>/dev/null
