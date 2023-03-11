#!/bin/bash

# CREATES A COMPLETELY TEMPORARY NETWORK AND VMS IN RAM BY DEFAULT FOR RAPID TESTING
# Add -p param to install vms persistently
# Run a second time to destroy all
# p makes pesistent vms that will remain after reboot

VMDIR="/var/ramdisk_vm"
MOUNTPT="/mnt"
SHOW_STATUS=1
GATEWAY_NIC="wlp42s0"  # My laptop wifi with internet, add nic as param or set here (nothing else needs set)
PERSISTENT=0
RAMDISK_SIZE="10G"
. common.sh
BLINK_STATUS="[$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR$BLINK_CURSOR]"
XMLPATH=

# FUNCTIONS...

CheckArgs() {
  [ ! -z $1 ] && GATEWAY_NIC=$1
  if [ "$2" == "p" ]; then
    PERSISTENT=1
    VMDIR="/var/lib/libvirt/images"
  fi
}

CreateRamdisk() {
  # Don't create ramdisk if persistent, use permanent storage, default vm location...
  if [ $PERSISTENT -eq 0 ]; then
    # Create and Mount Ramdisk - it is dynamic and will be deleted when shutdown occurs
    if [ ! -d $VMDIR ]; then
      #echo -n "$Ramdisk: RAMDISK_SIZE $VMDIR -> "
      mkdir -p $VMDIR
      mount -t tmpfs -o size=$RAMDISK_SIZE tmpfs $VMDIR
      #[ $? -ne 0 ] && echo "Failed!" && exit 1 || echo "Success!"
      [ $? -eq 0 ] && return 0 || return 1
    fi
  #else
    #echo "Using persistent storage: $VMDIR"
  fi
}

ErrorCheck() {
  echo -ne "\b\b\b\b\b\b\b\b\b"
  if [ $? -eq 0 ]; then
    [ "$SHOW_STATUS" -eq 1 ] && echo "[Success]"
  else
    [ "$SHOW_STATUS" -eq 1 ] && echo "[Failed]" && echo
    cat -n /tmp/error
    echo
    exit 1
  fi
}

Delete() {
  SHOW_STATUS=0
  echo
  read -p "VMs are running, STOP or RESTART? (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] && echo || exit 0
  RESTARTING=0
  read -p "Restart? (Y/N): " RESTART && [[ $RESTART == [yY] ]] && echo "Restarting..." && RESTARTING=1
  echo
  echo "DESTROYING SPAWNED VMS AND VNETS:"
  echo
  virsh net-destroy net10 >/dev/null 2>/tmp/error ; virsh net-destroy net172 >/dev/null 2>/tmp/error ; virsh net-destroy br192 >/dev/null 2>/tmp/error
  virsh destroy guest2 2>/dev/null ; virsh destroy guest3 2>/dev/null  ; virsh destroy guest4 2>/dev/null ; virsh destroy guest5 2>/dev/null
  if [ $PERSISTENT == 1 ]; then
    virsh net-undefine net10 >/dev/null 2>/tmp/error ; virsh net-undefine net172 >/dev/null 2>/tmp/error ; virsh net-undefine net192 >/dev/null 2>/tmp/error ; virsh net-undefine br192 >/dev/null 2>/tmp/error
    virsh undefine guest2 >/dev/null 2>/tmp/error ; virsh undefine guest3 >/dev/null 2>/tmp/error ; virsh undefine guest4 >/dev/null 2>/tmp/error ; virsh undefine guest5 >/dev/null 2>/tmp/error
  fi
  # Remove Ramdisk - it will be created and destroyed every time
  if [ $VMDIR == '/var/ramdisk_vm' ]; then
    # Only delete if it is the temporary storage
    rm -f $VMDIR/*
    umount $VMDIR
    rmdir $VMDIR
  else
    echo "VM's remain in $VMDIR"
  fi
  ip link del vrbr192
  ErrorCheck
  nft flush ruleset
  systemctl restart libvirtd ; sleep 2
  [ $RESTARTING -eq 0 ] && exit 0 || SHOW_STATUS=1
}

CopyIn() {
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
  fi
  # Copy multicasting programs
  mkdir $MOUNTPT/root/programs
  cp programs/* $MOUNTPT/root/programs/
  umount $MOUNTPT
}

CreateBridge() {
  ip link add vrbr192 type bridge >/dev/null 2>&1
  #ip link set enp43s0 master vrbr192 >/dev/null 2>&1
  ip address add dev vrbr192 192.168.255.1/24 >/dev/null 2>&1
  ip link set vrbr192 up >/dev/null 2>&1
}

IsRunning() {
  GetXmlPath
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
  #[ $? -ne 0 ] && echo "Error: Could not start default network" && exit 1 || echo "Started default network..."
}

NatSetup() {
# Add NAT for internet on wifi (replace $GATEWAY_NIC variable with your internet connected nic)
  nft add rule nat POSTROUTING oif $GATEWAY_NIC masquerade >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo
    echo -e "${YELLOW}Error: Change start.sh to include the interface name that is your gateway interface$NONE"
    echo
    exit 1
  fi
}

UpdateXmlConfig() {
  # Runs a python script that updates the vm directory in the virsh config
  python updatexml.py config/guest2/vm.xml $VMDIR/guest2.qcow2 >/dev/null
  python updatexml.py config/guest3/vm.xml $VMDIR/guest3.qcow2 >/dev/null
  python updatexml.py config/guest4/vm.xml $VMDIR/guest4.qcow2 >/dev/null
  python updatexml.py config/guest5/vm.xml $VMDIR/guest5.qcow2 >/dev/null
}

GetXmlPath() {
  XMLPATH=$(virsh domblklist guest3 2>&1 | awk 'FNR>0{print $2}' | tail -n+2)
  [[ $XMLPATH == */images/* ]] && PERSISTENT=1 && VMDIR="/var/lib/libvirt/images"
}








################ SCRIPT STARTS HERE #################
CheckArgs
IsRunning	# Will offer to shutdown or restart if running
GuestExists	# Will create guest if it doesn't exist
StartDefaultNetwork
NatSetup

echo "########## VM SETUP SCRIPT ##########"

# CREATE RAMDISK
echo -ne "CREATING RAMDISK:\t$BLINK_STATUS"
CreateRamdisk
ErrorCheck

#CREATE VNETS
echo -ne "CREATING VNETS:\t\t$BLINK_STATUS"
CreateBridge
if [ $PERSISTENT -eq 1 ]; then
  virsh net-define config/net10.xml >/dev/null 2>/tmp/error && virsh net-define config/net172.xml >/dev/null 2>/tmp/error && virsh net-define config/br192.xml >/dev/null 2>/tmp/error
  virsh net-start net10 >/dev/null 2>/tmp/error && virsh net-start net172 >/dev/null 2>/tmp/error && virsh net-start net192 >/dev/null 2>/tmp/error ; virsh net-start br192 >/dev/null 2>/tmp/error
else
  virsh net-create config/net10.xml >/dev/null 2>/tmp/error && virsh net-create config/net172.xml >/dev/null 2>/tmp/error && virsh net-create config/br192.xml >/dev/null 2>/tmp/error 
fi
ErrorCheck

# RESTART LIBVIRTD
echo -ne "RESTARTING LIBVIRTD:\t$BLINK_STATUS"
[ -f /tmp/error ] && rm /tmp/error
systemctl restart libvirtd
ErrorCheck
sleep 2	# Let libvirtd get started

# COPY VMS
echo -ne "COPYING VMS TO RAMDISK:\t$BLINK_STATUS"
cp guest.qcow2 $VMDIR/guest2.qcow2 && parallel cp $VMDIR/guest2.qcow2 ::: $VMDIR/guest3.qcow2 $VMDIR/guest4.qcow2 $VMDIR/guest5.qcow2
ErrorCheck

# COPY CONFIGS
echo -ne "COPYING CONFIGS TO VMS:\t$BLINK_STATUS"
CopyIn guest2 && CopyIn guest3 && CopyIn guest4 && CopyIn guest5
ErrorCheck

# CREATE VMS
echo -ne "VIRSH CREATE VMS:\t$BLINK_STATUS"
UpdateXmlConfig		# Python script that updates the filename within the xml every time
if [ $PERSISTENT == 1 ]; then
  virsh define config/guest2/vm.xml >/dev/null 2>/tmp/error && virsh define config/guest3/vm.xml >/dev/null 2>/tmp/error && virsh define config/guest4/vm.xml >/dev/null 2>/tmp/error && virsh define config/guest5/vm.xml >/dev/null 2>/tmp/error
  virsh start guest2 >/dev/null 2>/tmp/error && virsh start guest3 >/dev/null 2>/tmp/error && virsh start guest4 >/dev/null 2>/tmp/error && virsh start guest5 >/dev/null 2>/tmp/error
else
  virsh create config/guest2/vm.xml >/dev/null 2>/tmp/error && virsh create config/guest3/vm.xml >/dev/null 2>/tmp/error && virsh create config/guest4/vm.xml >/dev/null 2>/tmp/error && virsh create config/guest5/vm.xml >/dev/null 2>/tmp/error
fi
ErrorCheck

# CREATE ROUTE TO VMS
echo -ne "BRIDGE IPS:\t\t$BLINK_STATUS"
ip address del 172.16.16.1/24 dev virbr172 >/dev/null 2>/tmp/error
ip route add 172.16.16.0/24 via 10.0.0.2 >/dev/null 2>/tmp/error
#ip a add 192.168.255.254/24 dev enp43s0
# REPLACE VIRSH 192 BRIDGE WITH USB ETHERNET PORT AS BRIDGE
ErrorCheck

echo
echo "***********COMPLETED SUCCESSFULLY***********"
echo
virsh net-list --all
virsh list --all
echo "********************************************"
echo
echo -e "Run ${YELLOW}./addtobridge.sh ethX${NONE} if you want join bridge vrbr192 to connect a Raspberry Pi, for example"
echo
