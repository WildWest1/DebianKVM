#!/bin/bash

# Run to create aliases, or use for reference...
# Even better, append these aliases to your ~/.bashrc file so they are always available

alias virtm='virt-manager'	# GUI manager

alias v='virsh'

# VIRSH VM COMMANDS:
alias vlist='v list --all'
alias vl=vlist
alias vc='v console'
alias vdefine='v define'			# Defines persistent vm from xml
alias vauto='v autostart'
alias vedit='v edit'
alias vstart='v start'
alias vstop='v shutdown'
alias vreboot='v reboot'
alias vdestroy='v destroy'			# Stops vm, use undefine to delete
alias vattach='v attach-disk'
alias vqmc='v qemu-monitor-command'
alias vrename='v domrename'
alias vstate='v domstate'
alias vremove='v undefine'
alias vundefine='v undefine'
alias vattach='v attach-interface --source vibr192 --model virtio --type bridge --config --live --domain'	# Just specify the vm as param
alias vdetach='v detach-interface --type bridge --config --domain'
alias vdomiflist='v domiflist'
alias vdomifaddr='v domifaddr'	# Add dom as param
alias vdomiflink='v domif-getlink'	# Add dom to get link state
alias vdomsetlink='v domif-setlink'	# Add dom, up or down to set link state

# VIRSH NETWORK COMMANDS:
alias vnl=vnlist
alias vnlist='v net-list --all'
alias vndefine='v net-define'		# Creates persistent net from xml
alias vncreate='v net-create --file'	# Creates transient net from xml
alias vnauto='v net-autostart'
alias vnstart='v net-start'
alias vndestroy='v net-destroy'		# Stops net, or if undefined destorys it
alias vnedit='v net-edit'
alias vnundefine='v net-undefine' 		# Leaves net in tact but becomes transient, destroy to delete
alias vdumpxml='v dumpxml'
alias vninfo='v net-info'			# Add bridge name as optional param
alias vcpuinfo='v vcpuinfo'			# Add dom name param
alias vcpucount='v vcpucount'
alias vcpus='v vcpus'
alias vsetmem='v setmem'			# Add memory to vm (dom totalmem)

# Passthrough:
alias vnodelist='v nodedev-list'		# Convert format to: pci_0000_04_00_0 (replace colons and periods with underscores)
alias vnodedump='v nodedev-dumpxml'		# Add pci id to get xml (note domain bus slot function)
alias vnodedetach='v nodedev-detach'	# Add pci name to detach from host
alias vnodeattach='v nodedev-attach'	# Add dom and pathToXml (created from dumpxml values) to attach to guest
alias vnetdump='v net-dumpxml'
alias vnetdumpass='v net-dumpxml passthrough'
alias vnodetree='v nodedev-list --tree'
alias vnodepci='v nodedev-list|grep pci'
