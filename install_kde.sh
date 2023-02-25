#!/bin/bash

# Installs KDE on usb host (optional)

apt install -y kde-plasma-desktop kde-standard kdeadmin kdegraphics kdemultimedia kdenetwork kdeutils xorg firefox-esr

. common.sh

echo
echo -e "Create user by running${YELLOW} adduser user ${NONE}or you won't be able to logon to windows"
echo -e "Then you can run ${YELLOW}startx${NONE} or reboot to launch windows"
echo
