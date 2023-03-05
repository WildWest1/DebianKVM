#!/bin/bash

# CREATES A COMPLETELY TEMPORARY NETWORK AND VMS IN RAM BY DEFAULT FOR RAPID TESTING
# Add -p param to install vms persistently
# Run a second time to destroy all
# p makes pesistent vms that will remain after reboot

VMDIR="/var/ramdisk/guest.qcow22"


UpdateXmlConfig() {
  # Runs a python script that updates the vm directory in the virsh config
  python updatexml.py config/guest2/vm.xml $VMDIR
  python updatexml.py config/guest3/vm.xml $VMDIR
  python updatexml.py config/guest4/vm.xml $VMDIR
}

UpdateXmlConfig
