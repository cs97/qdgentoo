#! /bin/bash

USER='user'

banner(){
	clear
	echo "##########################################"
	echo "#                                        #"
	echo "#             qdgentoo-stuff             #"
	echo "#                                        #"
	echo "##########################################"
	echo "user: $USER"
	echo "##########################################"
	echo "#  0  add user                           #"
	echo "#  1  xorg-server                        #"
	echo "#  2  i3                                 #"
	echo "#  3  firefox                            #"
	echo "#  4  stuff                              #"
	echo "#  5  android-tools                      #"
	echo "#  19 elogind                            #"
	echo "#  99 update                             #"
	echo "##########################################"
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
		cp qdgentoo-stuff.sh /home/$USER/qdgentoo-stuff.sh
		emerge xrandr
		echo "user:" $USER
		usermod -a -G video $USER
		usermod -a -G input $USER;;
	"1") 
		USE="-suid" emerge --ask x11-base/xorg-server
		echo 'SUBSYSTEM=="input", ACTION=="add", GROUP="input"' > /etc/udev/rules.d/99-dev-input-group.rules
		emerge --ask pulseaudio alsa-mixer alsa-utils
		#emerge --ask x11-base/xorg-server --autounmask-write; source /etc/profile
		#emerge --ask x11-base/xorg-server; source /etc/profile
		;;
	"2")
		emerge --ask x11-wm/i3 x11-misc/i3status x11-misc/i3lock x11-terms/xterm edia-gfx/feh sys-process/htop
		echo "exec i3" > ~/.xinitrc
		mv ~/.config/i3/config ~/.config/i3/config.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/config
		mv ~/config ~/.config/i3/config;;
	"3")
		emerge --ask www-client/firefox;;
	"4")
		emerge --ask app-misc/screenfetch sys-apps/lm-sensors x11-apps/xbacklight app-misc/mc cdrtools thunar file-roller;;	
	"5")
		emerge --ask dev-util/android-tools;;
	"6") 
		emerge --ask elogind
		rc-update add elogind boot;;

	"99")
		mv qdgentoo-stuff.sh qdgentoo-stuff.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/qdgentoo-stuff.sh
		chmod +x qdgentoo-stuff.sh;;

	*) banner;;
esac
exit
