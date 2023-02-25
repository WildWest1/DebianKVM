#!/bin/bash

# CREATES A COMPLETELY TEMPORARY NETWORK AND VMS IN RAM
# r destroys all instantly
# p makes pesistent vms

VMDIR="/var/ramdisk"
MOUNTPT="/mnt"
BLINK_STATUS="[$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR]"
SHOW_STATUS=1

PERSISTENT=0
REMOVE=0

. common.sh

# GET ARGS
[ "$1" == "p" ] || [ "$2" == "p" ] && PERSISTENT=1
[ "$1" == "r" ] || [ "$2" == "r" ] && REMOVE=1


# FUNCTIONS...

function ErrorCheck {
  if [ $? -eq 0 ]; then
    [ "$SHOW_STATUS" -eq 1 ] && echo "[Success]"
  else
    [ "$SHOW_STATUS" -eq 1 ] && echo "[Failed]" && echo
    cat -n /tmp/error
    echo
    exit 1
  fi
}

function Delete {
  SHOW_STATUS=0
  echo
  read -p "VMs are running, STOP or RESTART? (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] && echo || exit 0
  RESTARTING=0
  read -p "Restart? (Y/N): " RESTART && [[ $RESTART == [yY] ]] && echo "Restarting..." && RESTARTING=1
  echo
  echo "DESTROYING SPAWNED VMS AND VNETS:"
  echo
  virsh net-destroy net10 >/dev/null 2>/tmp/error ; virsh net-destroy net172 >/dev/null 2>/tmp/error ; virsh net-destroy br192 >/dev/null 2>/tmp/error
  virsh destroy guest2 2>/dev/null ; virsh destroy guest3 2>/dev/null ; virsh destroy guest4 2>/dev/null
  if [ $PERSISTENT == 1 ]; then
    virsh net-undefine net10 >/dev/null 2>/tmp/error ; virsh net-undefine net172 >/dev/null 2>/tmp/error ; virsh net-undefine net192 >/dev/null 2>/tmp/error ; virsh net-undefine br192 >/dev/null 2>/tmp/error
    virsh undefine guest2 >/dev/null 2>/tmp/error ; virsh undefine guest3 >/dev/null 2>/tmp/error ; virsh undefine guest4 >/dev/null 2>/tmp/error
  fi
  ip link del vrbr192
  ErrorCheck
  nft flush ruleset
  systemctl restart libvirtd ; sleep 2
  [ $RESTARTING -eq 0 ] && exit 0 || SHOW_STATUS=1
}

function CopyIn {
  HOST=$1
  guestmount -a $VMDIR/$HOST.qcow2 -i $MOUNTPT
  cp config/$HOST/hostname $MOUNTPT/etc/
  cp config/$HOST/interfaces $MOUNTPT/etc/network/
  cp config/common/sleep.conf $MOUNTPT/etc/systemd
  cp config/common/sysctl.conf $MOUNTPT/etc/
  cp config/common/sshd_config $MOUNTPT/etc/ssh/
  cp config/$HOST/nftables.conf $MOUNTPT/etc/
  cp config/common/.bashrc $MOUNTPT/root
  cp config/common/up.sh $MOUNTPT/root
  cp config/common/resolv.conf $MOUNTPT/etc/
  if [ "$HOST" == "guest3" ]; then
    # ADD OPENVPN CLIENT
    mkdir -p $MOUNTPT/etc/openvpn
    cp config/$HOST/vpn-auth $MOUNTPT/etc/openvpn
    cp config/$HOST/vpn.ovpn $MOUNTPT/etc/openvpn
    cp config/$HOST/rc.local $MOUNTPT/etc/
    #cp config/$HOST/startup.service $MOUNTPT/lib/systemd/system/
    #cp $MOUNTPT/lib/systemd/system/startup.service $MOUNTPT/etc/systemd/system/multi-user.target.wants/
  fi
  if [ "$HOST" == "guest4" ]; then
    # ADD DNS SERVER:
    mkdir -p $MOUNTPT/etc/bind
    mkdir -p $MOUNTPT/etc/bind/backup
    cp config/$HOST/forward.my.lan.db $MOUNTPT/etc/bind/backup/
    cp config/$HOST/reverse.my.lan.db $MOUNTPT/etc/bind/backup/
    cp config/$HOST/named.conf.local $MOUNTPT/etc/bind/backup/
    cp config/$HOST/named.conf.options $MOUNTPT/etc/bind/backup/
    cp config/common/resolv.conf $MOUNTPT/etc/resolv.host
    cp config/$HOST/resolv.conf $MOUNTPT/etc/
    cp config/$HOST/rc.local $MOUNTPT/etc/
    #cp config/$HOST/startup.service $MOUNTPT/lib/systemd/system/
    #cp $MOUNTPT/lib/systemd/system/startup.service $MOUNTPT/etc/systemd/system/multi-user.target.wants/
  fi
  umount $MOUNTPT
}

function CreateBridge {
  ip link add vrbr192 type bridge >/dev/null 2>&1
  ip link set enx00e04c680c11 master vrbr192 >/dev/null 2>&1
  ip address add dev vrbr192 192.168.255.1/24 >/dev/null 2>&1
  ip link set vrbr192 up >/dev/null 2>&1
}

function IsRunning {
  virsh domstate guest2 >/dev/null 2>&1
  GUESTEXISTS=$?
  virsh net-info br192 >/dev/null 2>&1
  NETEXISTS=$?
  [[ $GUESTEXISTS -eq 0 || NETEXISTS -eq 0 ]] && Delete
}


GuestExists() {
  FOUND=0
  [ ! -f guest.qcow2 ] && ./setup.sh || FOUND=1
  [ $FOUND -eq 0 ] && echo "Creation of guest image failed, exiting." && exit 1
}

StartDefaultNetwork() {
  virsh net-start default >/dev/null 2>&1
}

################ SCRIPT STARTS HERE #################

##### RESTART/DELETE IF RUNNING #####
IsRunning

GuestExists

StartDefaultNetwork

# Add NAT for internet on wiri (replace wlp2s0 with your internet connected nic)
nft add rule nat POSTROUTING oif wlp2s0 masquerade >/dev/null 2>&1

##### INTSTALL #####
echo "########## VM SETUP SCRIPT ##########"
echo
echo -ne "CREATING VNETS:\t\t"
CreateBridge
if [ $PERSISTENT -eq 1 ]; then
  virsh net-define config/net10.xml >/dev/null 2>/tmp/error && virsh net-define config/net172.xml >/dev/null 2>/tmp/error && virsh net-define config/br192.xml >/dev/null 2>/tmp/error 
  virsh net-start net10 >/dev/null 2>/tmp/error && virsh net-start net172 >/dev/null 2>/tmp/error && virsh net-start net192 >/dev/null 2>/tmp/error ; virsh net-start br192 >/dev/null 2>/tmp/error
else
  virsh net-create config/net10.xml >/dev/null 2>/tmp/error && virsh net-create config/net172.xml >/dev/null 2>/tmp/error && virsh net-create config/br192.xml >/dev/null 2>/tmp/error 
fi
ErrorCheck

echo -ne "RESTARTING LIBVIRTD:\t"
[ -f /tmp/error ] && rm /tmp/error
systemctl restart libvirtd ; sleep 2
ErrorCheck

echo -ne "COPYING VMS TO RAMDISK:\t$BLINK_STATUS"
cp guest.qcow2 $VMDIR/guest2.qcow2 && parallel cp $VMDIR/guest2.qcow2 ::: $VMDIR/guest3.qcow2 $VMDIR/guest4.qcow2
echo -ne "\b\b\b\b\b\b\b\b\b"
ErrorCheck

echo -ne "COPYING CONFIGS TO VMS:\t$BLINK_STATUS"
CopyIn guest2 && CopyIn guest3 && CopyIn guest4
echo -ne "\b\b\b\b\b\b\b\b\b"
ErrorCheck

echo -ne "VIRSH CREATE VMS:\t$BLINK_STATUS"
if [ $PERSISTENT == 1 ]; then
  virsh define config/guest2/vm.xml >/dev/null 2>/tmp/error && virsh define config/guest3/vm.xml >/dev/null 2>/tmp/error && virsh define config/guest4/vm.xml >/dev/null 2>/tmp/error
  virsh start guest2 >/dev/null 2>/tmp/error && virsh start guest3 >/dev/null 2>/tmp/error && virsh start guest4 >/dev/null 2>/tmp/error 
else
  virsh create config/guest2/vm.xml >/dev/null 2>/tmp/error && virsh create config/guest3/vm.xml >/dev/null 2>/tmp/error && virsh create config/guest4/vm.xml >/dev/null 2>/tmp/error
fi
echo -ne "\b\b\b\b\b\b\b\b\b"
ErrorCheck

echo -ne "BRIDGE IPS:\t\t"
ip address del 172.16.16.1/24 dev virbr172 >/dev/null 2>/tmp/error
ip route add 172.16.16.0/24 via 10.0.0.2 >/dev/null 2>/tmp/error
#ip a add 192.168.255.254/24 dev enx00e04c680c11
# REPLACE VIRSH 192 BRIDGE WITH USB ETHERNET PORT AS BRIDGE
ErrorCheck

echo
echo "***********COMPLETED SUCCESSFULLY***********"
echo
virsh net-list --all
virsh list --all
echo "********************************************"
