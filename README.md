# DebianKVM
These scripts automate creating guest and host VM’s for testing and learning
The goal is to make a bootable flash drive that is a self contained vm host with multiple configurable guests, however, the guests can run on any ubuntu or debian based installation without needing to run on a flash drive

A Makefile has been added to simplify bootstraping
Usage:
- make or make guest - Builds a single guest vm called guest.qcow2 (bios) that can be launched on the current system using the launch scripts or demonstrate a full virtual network of vms by running start.sh
- make host - Builds a 30G vm host.img with guest.qcow2 inside it, which can be run on the current system by using the launch scripts, or can be made into a bootable flash drive by running make_bootable_usb.sh
- make usb - Same as above, except make_bootable_usb.sh runs automatically after finished building (recommended)
 
Misc:
-   ./install_kde.sh - this script will add kde windows within the host.img
-   ./deploy.sh guest.qcow2 - launches the vm and starts immediately on the current host
-   ./virshaliases.sh - adds aliases for controlling vms from the command line (alternatively, you can run virt-manager for GUI, if available
-   ./start.sh - creates 3 vms (guest4 dns server, guest 3 a vpn server hiding guest4, and guest2 an optional router for guest4), plus the host can nat all traffic to provide internet 
NOTE: If you want to run these on a laptop with wifi then it would be best to figure out the debian firmware apt package and add your firmware to the _h.sh file (where it is installing with apt). Then when you reboot to the flash drive you can just run ./wifi.sh [wifinic] to connect to the internet.
