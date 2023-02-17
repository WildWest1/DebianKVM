# DebianKVM
Create Debian VM's without requiring any installation media, and make bootable host/guest combo

Makefile is to help bootstrap simple setups.
Usage:
- make - will make a minimal guest vm
- make host.img - will make a 10G vm host with guest.qcow2 inside it, and then you can run make_bootable_usb.sh to have it run on hw
  
The intention of this script is to quickly create a framework for experimenting with KVM vms, so that you can copy one the guest.qcow2 into as many customizable vms as you want by using virsh xml files and guestfish.

Misc:
-   ./deploy.sh guest.qcow2 - launches the vm and starts immediately on the current host
-   ./make_bootable_usb.sh host.img - converts the vm image to run on hardware
-   ./virshaliases.sh - adds aliases for controlling vms from the command line (alternatively, you can run virt-manager for GUI, if available
 
