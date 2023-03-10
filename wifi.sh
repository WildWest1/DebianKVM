#!/bin/bash

# Setup wpa supplicant to authenticate to wifi - only needs run once if you set a static ip

Usage() {
  echo "Sets up wifi authentcation to happen at every boot"
  echo "Initial setup (required), or to update SSID/Pass:"
  echo "  Usage: ./wifi.sh [wifiNic] [wifiSSID] [wifiPassword]"
  echo "Manually requthenticate to wifi:"
  echo "  Usage: ./wifi.sh [wifiNic]"
  exit 1
}

[ -z $1 ] && Usage

WIFINIC=$1
SSID=$2
PASS=$3


# Make sure these are installed...
# Firmware is like the driver, my laptop has qualcomm atheros so firmware-atheros, yours may have intel wireless which is firmware-iwlwifi, or find the apt package for your wireless adapter and install it
# Wpasupplicant is the client software that will connect us to the wifi and handle authentication
#      apt install -y  wpasupplicant wireless-tools firmware-atheros #firmware->iwlwifi
# To find what kind of wireless nic you have, try \"lspci | grep Wireless\"

# Stop any existing wpa_supplicant
pkill wpa >/dev/null 2>&1
#ip link set $WIFINIC down

if [[ ! -z $2 && ! -z $3 ]]; then
  # Enable wpa_supplicant to automatically login to wifi
  cp /lib/systemd/system/wpa_supplicant.service /etc/systemd/system/wpa_supplicant.service
  # Add restart=always by extending the config (ratherthan trying to add to section and checking if already there)
  mkdir -p /etc/systemd/system/wpa_supplicant.service.d
  echo -e "[Service]\nRestart=always" > /etc/systemd/system/wpa_supplicant.service.d/wpa_supplicant.conf
  # Replace ExecStart setting
  KEY=ExecStart
  VALUE="/sbin/wpa_supplicant -u -s -c /etc/wpa_supplicant/wpa_supplicant.conf -i ${WIFINIC}"
  sed -i "s?$KEY=.*?$KEY=$VALUE?" /etc/systemd/system/wpa_supplicant.service
  # Replace After setting
  KEY=After
  VALUE="dbus.service networking.service"
  sed -i "s?$KEY=.*?$KEY=$VALUE?" /etc/systemd/system/wpa_supplicant.service
  # Update and set service to start automatically
  systemctl daemon-reload
  systemctl enable wpa_supplicant
  # Add wifi config
  wpa_passphrase $SSID $PASS > /etc/wpa_supplicant/wpa_supplicant.conf
fi

# Static IP is recommended, or else you'll need to run dhclient every boot, since it needs to run after authentication, not when the nic is brought online
# Example /etc/network/interface:
# auto wlp2s0
# iface wlp2s0 inet static
#  address 192.168.0.200/24
#  gateway 192.168.0.1

# If you want to use dhcp, you may need to configure your /etc/network/interface like this due to timing issues:
# auto wlp2s0
# iface wlp2s0 inet manual

echo "---------------------------------"
echo "Bringing ${WIFINIC} up..."
#ip link set $WIFINIC up
systemctl restart networking	# Just in case changes were made to /etc/networking/interface

if [ -z $2 ]; then
  # MANUAL process (not dependent on anything above other than the wpa config)
  echo Logging on to Wireless network...
  wpa_supplicant -u -s -c /etc/wpa_supplicant/wpa_supplicant.conf  -i $WIFINIC >/dev/null 2>&1 &
else
  # Automatic process
  echo "Restarting wpa_supplicant..."
  systemctl restart wpa_supplicant &
  #sleep 5
fi

#echo "Obtaining DHCP..."
#dhclient $WIFINIC &
#sleep 5

echo "---------------------------------"
echo "Done."
echo
ip a s $WIFINIC
echo
