# DebianKVM
Scripts that automate creating guest and host VM’s individually or together, make bootable flash drive, etc.

Makefile is to help bootstrap simple setups.
Usage:
  make guest.qcow2 will make a minimal guest vm
  make host.img will make a 10G vm host with guest.qcow2 inside it, and then you can run make_bootable_usb.sh to have it run on hw
  
 Note that the intention of this script is to quickly create a framework for experimenting with KVM so that you can copy the guest.qcow2 into as many little vms running on the host as you want
 Misc:
   ./deploy.sh guest.qcow2 - launches the vm and starts immediately on the current host
   ./make_bootable_usb.sh host.img - converts the vm image to run on hardware
   ./virshaliases.sh - adds aliases for controlling vms from the command line (alternatively, you can run virt-manager for GUI, if available
 
