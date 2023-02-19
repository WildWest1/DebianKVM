# DebianKVM
Scripts that automate creating guest and host VM’s individually or together, make bootable flash drive, etc.

Makefile is to help bootstrap simple setups.
Usage:
- make - will make a minimal guest vm
- make host.img - will make a 10G vm host with guest.qcow2 inside it, and then you can run make_bootable_usb.sh to have it run on hw
 
The intention of this script is to quickly create a framework for experimenting with KVM vms, so that you can copy one the guest.qcow2 into as many customizable vms as you want by using virsh xml files and guestfish.

Misc:
-   ./deploy.sh guest.qcow2 - launches the vm and starts immediately on the current host
-   ./make_bootable_usb.sh host.img - converts the vm image to run on hardware
-   ./virshaliases.sh - adds aliases for controlling vms from the command line (alternatively, you can run virt-manager for GUI, if available
 
NOTE: If you want to run these on a laptop with wifi then it would be best to figure out the debian firmware apt package and add your firmware to the _h.sh file (where it is installing with apt). Then when you reboot to the flash drive you can just run ./wifi.sh to connect to the internet.
