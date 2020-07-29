#! /bin/bash

USER='user'

GITURL="https://raw.githubusercontent.com/l3f7s1d3/qdgentoo/master/qdgentoo-stuff.sh"

kernel='=sys-kernel/gentoo-sources-5.7.10 ~amd64'
virtualbox='=app-emulation/virtualbox-6.1.6 ~amd64'
virtualbox_modules='=app-emulation/virtualbox-modules-6.1.6 ~amd64'

banner(){
	clear
	echo "##########################################"
	echo "#                                        #"
	echo "#             qdgentoo-stuff             #"
	echo "#                                        #"
	echo "##########################################"
	echo "run on" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
	echo "$kernel"
	echo "$virtualbox"
	echo "$virtualbox_modules"
	echo "##########################################"
	echo "#                                        #"
	echo "#  0  xorg-server                        #"
	echo "#  1  i3                                 #"
	echo "#  2  ~/.xinitrc                         #"
	echo "#  3  xterm                              #"
	echo "#  4  i3status                           #"
	echo "#  5  i3lock                             #"
	echo "#  6  stuff                              #"
	echo "#  7  firefox                            #"
	echo "#  8  virtualbox                         #"
	echo "#  9  makeuser                           #"
	echo "#  10 wifi                               #"
	echo "#  11 i3config                           #"
	echo "#  12 audio                              #"
	echo "#  13 powersave                          #"
	echo "#  14                                    #"
	echo "#  15 thunar                             #"
	echo "#  16 file-roller                        #"
	echo "#  17 mc                                 #"
	echo "#  18 no root xorg-server                #"
	echo "#  19 cdrtools                           #"
	echo "#  99 update                             #"
	echo "##########################################"
	echo ""
}

################################	20
xorg_install(){
	emerge --ask x11-base/xorg-server
	#emerge --ask x11-base/xorg-server --autounmask-write; source /etc/profile
	#etc-update
	#emerge --ask x11-base/xorg-server; source /etc/profile
}
################################	28
virtualbox_install(){
	echo "$virtualbox" >> /etc/portage/package.accept_keywords
	echo "$virtualbox_modules" >> /etc/portage/package.accept_keywords
	emerge --ask app-emulation/virtualbox
	modprobe vboxdrv
}
################################	33
cpupower_install(){
	emerge sys-power/cpupower
	echo '#!/bin/bash' > /etc/local.d/powersave.start
	echo 'cpupower frequency-set -g powersave' >> /etc/local.d/powersave.start
	chmod +x /etc/local.d/powersave.start
	rc-update add local default
}
################################	666
nvme_efi_aes(){
	disk='/dev/nvme0n1'		
	uefi='/dev/nvme0n1p1'	# 2M		(bootloader)
	boot='/dev/nvme0n1p2'	# 512M		(fat32 UEFI)
	root='/dev/nvme0n1p3'	# 100%FREE	(lvm)

	cfdisk $disk
	sleep 1
	mkfs.fat -F 32 $boot
	makefs_aes		#0
}
################################	666_2
nvme_efi_aes_2(){
	disk='/dev/nvme0n1'		
	uefi='/dev/nvme0n1p1'	# 2M		(bootloader)
	boot='/dev/nvme0n1p2'	# 512M		(fat32 UEFI)
	root='/dev/nvme0n1p3'	# 100%FREE	(lvm)

	do_in_chroot		#1
	at_world		#2
	make_locale		#3
	env_update		#4
	gentoo_sources		#5
	pci_utils		#6
	gentoo_genkernel_aes	#7
	etc-update
	gentoo_genkernel_aes	#7
	fstab_stuff_aes		#8
	install_grub_aes_efi	#9
}


case $1 in

	"0") xorg_install;;
	"1") emerge --ask x11-wm/i3;;
	"2") echo "exec i3" >> ~/.xinitrc;;
	"3") emerge --ask x11-terms/xterm;;
	"4") emerge --ask x11-misc/i3status;;
	"5") emerge --ask x11-misc/i3lock;;
	"6") emerge media-gfx/feh app-misc/screenfetch sys-apps/lm-sensors x11-apps/xbacklight sys-process/htop;;
	"7") emerge --ask www-client/firefox;;
	"8") virtualbox_install;;
	"9") #user
		emerge --ask app-admin/sudo
		useradd -m -G users,wheel,audio -s /bin/bash $USER
		echo "exec i3" >> /home/$USER/.xinitrc
		echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
		passwd $USER
#		passwd -l root
		cp qdgentoo.sh /home/$USER/qdgentoo.sh
		emerge xrandr
		echo "user:" $USER;;
	"10") emerge --ask net-wireless/iw net-wireless/wpa_supplicant;;
	"11")
		wget $GITURL/config
		mv ~/.config/i3/config ~/.config/i3/config.old
		mv ~/config ~/.config/i3/config;;
	"12") emerge --ask pulseaudio alsa-mixer alsa-utils;;
	"13") cpupower_install;;
	"15") emerge --ask thunar; ;;
	"16") emerge --ask file-roller;;
	"17") emerge --ask app-misc/mc;;
	"18")
		USE="-suid" emerge --update --deep --newuse --verbose --ask xorg-server
		echo 'SUBSYSTEM=="input", ACTION=="add", GROUP="input"' >> /etc/udev/rules.d/99-dev-input-group.rules
		usermod -a -G video $USER
		usermod -a -G input $USER;;
	"19") emerge --ask cdrtools;;

	"99")
		mv qdgentoo-stuff.sh qdgentoo-stuff.old
		wget $GITURL
		chmod +x qdgentoo-stuff.sh;;

	*) banner;;
esac
exit
