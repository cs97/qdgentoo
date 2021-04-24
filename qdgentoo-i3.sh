#! /bin/bash

USER='user'

banner(){
	clear
	echo ""
	echo ""
	echo -e "\t\tqdgentoo-i3"
	echo ""
	echo -e "\tuser: $USER"
	echo ""
	echo -e "\t0. add user"
	echo -e "\t1. xorg-server"
	echo -e "\t2. i3"
	echo -e "\t99. update"
	echo ""
}

case $1 in
	"0")
		emerge --ask app-admin/sudo
		useradd -m -G users,wheel,audio -s /bin/bash $USER
		echo "exec i3" >> /home/$USER/.xinitrc
		echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
		passwd $USER
#		passwd -l root
		cp qdgentoo-i3.sh /home/$USER/qdgentoo-i3.sh
		emerge xrandr
		echo "user:" $USER
		usermod -a -G video $USER
		usermod -a -G input $USER;;
	"1") 
		USE="-suid" emerge --ask x11-base/xorg-server
		#echo 'SUBSYSTEM=="input", ACTION=="add", GROUP="input"' > /etc/udev/rules.d/99-dev-input-group.rules
		emerge --ask pulseaudio alsa-mixer alsa-utils
		#emerge --ask x11-base/xorg-server --autounmask-write; source /etc/profile
		#emerge --ask x11-base/xorg-server; source /etc/profile
		;;
	"2")
		emerge --ask x11-wm/i3 x11-misc/i3status x11-misc/i3lock x11-terms/xterm sys-process/htop #edia-gfx/feh
		echo "exec i3" > ~/.xinitrc
		mv ~/.config/i3/config ~/.config/i3/config.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/conf/config
		mv ~/config ~/.config/i3/config;;
	"99")
		mv qdgentoo-i3.sh qdgentoo-i3.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/qdgentoo-i3.sh
		chmod +x qdgentoo-i3.sh;;
	*) banner;;
esac
exit
