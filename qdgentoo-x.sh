#! /bin/bash

USER='user'
BACKGROUND='~/pic.png'


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
	echo -e "\t3. i3 new config"
	echo -e "\t4. dwm"
	echo -e "\t5. audio"
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
		#emerge --ask x11-base/xorg-server --autounmask-write; source /etc/profile
		#emerge --ask x11-base/xorg-server; source /etc/profile
		;;
	"2")
		emerge --ask x11-wm/i3 x11-misc/i3status x11-misc/i3lock x11-terms/xterm sys-process/htop #edia-gfx/feh
		echo "exec i3" > ~/.xinitrc
		;;
		
	"3")
		mv ~/.config/i3/config ~/.config/i3/config.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/conf/config
		mv ~/config ~/.config/i3/config
		;;
	"4")
		emerge --ask dwm
		emerge --ask dmenu
		emerge --ask feh
		#emerge --ask conky
		#conky --print-config > ~/.config/conky.conf
		echo "feh --bg-center $BACKGROUND" > ~/.xinitrc
		#echo "conky -c ~/.config/conky.conf" >> ~/.xinitrc
		echo "exec dwm" >> ~/.xinitrc
		#conky.conf
		#background = true,
		#own_window = false,
		;;
	"5")
		emerge --ask pulseaudio alsa-mixer alsa-utils
		;;
	"99")
		mv qdgentoo-i3.sh qdgentoo-i3.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/qdgentoo-i3.sh
		chmod +x qdgentoo-i3.sh;;
	*) banner;;
esac
exit
