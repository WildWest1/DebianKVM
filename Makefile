default: guest.qcow2

.PHONY: guest

guest: guest.qcow2

.PHONY: host

host: host.img

.PHONY: usb

usb: host.img
	./make_bootable_usb.sh host.img

guest.qcow2:
	# Making guest.qcow2
	./setup.sh guest.qcow2 2

host.img: guest.qcow2
	# Making a bootable usb from host.img that contains a guest.qcow2
	@echo "Making host.img..."
	@./setup.sh host.img 100 nodetach; \
	if [ $$? -eq 0 ]; then  \
		echo "Makefile copying guest.qcow2 to host..." ; \
		cp guest.qcow2 root/root ; \
		cp *.sh root/root/ ; \
		./detach.sh ; \
		echo ; echo "RUN:  \"./make_bootable_usb.sh host.img\"";echo ; \
	fi

clean:
	# Remove all images and start fresh
	- ./detach.sh
	@echo "Deleting all images"
	- rm -rf *.qcow2 *.img *.raw *.qcow root boot
	@echo "Removing guest.qcow2 vm..."
	- virsh destroy guest.qcow2 2>/dev/null
	- virsh undefine guest.qcow2 >2/dev/null
	@echo
	@echo
	virsh list --all
