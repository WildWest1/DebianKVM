apt install kde-plasma-desktop kde-standard kdeadmin kdegraphics kdemultimedia kdenetwork kdeutils xorg firefox-esr

. common.sh

echo
echo "Creating user TEST with password PASSWORD..."
echo -e "password\npassword\n\n\n\n\n\n\n" | adduser test >/dev/null 2>&1
[ $? -ne 0 ] && echo -e "${RED}Failed to create standard user necessary for kde login${NONE}" && echo "Create new user now, or you will need to use ctrl+alt+F2 to add after reboot" || echo "Done"
echo
