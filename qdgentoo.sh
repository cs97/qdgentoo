#! /bin/bash

SERVERURL="https://raw.githubusercontent.com/l3f7s1d3/qdgentoo/master/"
STAGE=''
STAGE3URL='distfiles.gentoo.org/releases/amd64/autobuilds/20200205T214502Z/stage3-amd64-20200205T214502Z.tar.xz'
USER=$2
disk='/dev/sda'
boot='/dev/sda1'
root='/dev/sda2'

if [ -z "$1" ]; then
	clear
	echo "######################################"
	echo "# #                                # #"
	echo "#   #                            #   #"
	echo "#     #                        #     #"
	echo "#       ######################       #"
	echo "#       #                    #       #"
	echo "#       #      qdgentoo      #       #"
	echo "#       #      v0.3          #       #"
	echo "#       ######################       #"
	echo "#     #                        #     #"
	echo "#   #                            #   #"
	echo "# #                                # #"
	echo "######################################"
	echo "#                                    #"
	echo "# 0. makefs                          #"
	echo "# 1. do in chroot                    #"
	echo "# 2. @world                          #"
	echo "# 3. locale                          #"
	echo "# 4. env-update                      #"
	echo "# 5. gentoo-sources                  #"
	echo "# 6. pciutils                        #"
	echo "# 7. genkernel                       #"
	echo "# 8. fstab & Stuff                   #"
	echo "# 9. grub                            #"
	echo "# 10.lsmod > /lsmod.txt              #"
	echo "# 11.reboot                          #"
	echo "#                                    #"
	echo "# 20. xorg-server                    #"
	echo "# 21. i3                             #"
	echo "# 22. ~/.xinitrc                     #"
	echo "# 23. xterm                          #"
	echo "# 24. i3status                       #"
	echo "# 25. i3lock                         #"
	echo "# 26. stuff                          #"
	echo "# 27. firefox                        #"
	echo "# 28. virtualbox                     #"
	echo "# 29. makeuser <username>            #"
	echo "# 30. wifi                           #"
	echo "# 31. i3config                       #
	echo "#                                    #"
	echo "# 99. update                         #"
	echo "######################################"
	echo ""
	exit
fi

################################	0
if [ $1 == '0' ]; then
	cfdisk $disk	
	mkfs.ext4 $boot
	mkfs.ext4 $root
	mount $root /mnt/gentoo
	cd /mnt/gentoo
	wget -O stage3.tar.xz $STAGE3URL
	tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner
	nano -w /mnt/gentoo/etc/portage/make.conf
	#COMMON_FLAGS="-march=native -O2 -pipe" 
	#MAKEOPTS="-j3"			
	mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
	mkdir --parents /mnt/gentoo/etc/portage/repos.conf
	cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
	cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
	mount --types proc /proc /mnt/gentoo/proc
	sleep 1
	mount --rbind /sys /mnt/gentoo/sys
	sleep 1
	mount --make-rslave /mnt/gentoo/sys
	sleep 1
	mount --rbind /dev /mnt/gentoo/dev
	sleep 1
	mount --make-rslave /mnt/gentoo/dev
	sleep 1
	cp ~/qdgentoo.sh /mnt/gentoo/qdgentoo.sh
	echo "##########################################"
	echo "now 1"
	chroot /mnt/gentoo /bin/bash
fi

################################	1
if [ $1 == '1' ]; then
	source /etc/profile
	export PS1="(chroot) ${PS1}"
	mount $boot /boot
	emerge-webrsync
	emerge --sync
	clear

	eselect profile list
	echo "##########################################"
	echo "eselect profile set X"		#skipt
	echo "now 2"
	exit
fi

################################	2
if [ $1 == '2' ]; then
	emerge --ask --verbose --update --deep --newuse @world			
	echo "##########################################"
	echo "now 3"
	exit
fi

################################	3
if [ $1 == '3' ]; then
#	portageq envvar ACCEPT_LICENSE @FREE
	echo "Europe/Berlin" > /etc/timezone
	emerge --config sys-libs/timezone-data
	nano -w /etc/locale.gen
#	 echo>>
	locale-gen
	clear
	eselect locale list
	echo "##########################################"
	echo "eselect locale set X"
	echo "now 4"
	exit
fi

################################	4
if [ $1 == '4' ]; then
	env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
	etc-update
	echo "##########################################"
	echo "now 5"
	exit
fi

################################	5
if [ $1 == '5' ]; then
	emerge --ask sys-kernel/gentoo-sources
	etc-update
	echo "##########################################"
	echo "now 6"
	exit
fi

################################	6
if [ $1 == '6' ]; then
	emerge --ask sys-apps/pciutils
#	lspci
	etc-update
	echo "##########################################"
	echo "now 7"
	exit
fi

################################	7
if [ $1 == '7' ]; then
	echo "sys-kernel/gentoo-sources" >> /etc/portage/package.use
	emerge --ask genkernel
	etc-update

#	genkernel all
	genkernel --menuconfig all
	echo "##########################################"
	echo "now 8"
	exit
fi

################################	8
if [ $1 == '8' ]; then
	etc-update
	emerge --ask sys-kernel/linux-firmware
	etc-update
	#nano -w /etc/fstab
	echo "$root		/root		ext4		defaults        0 1" >> /etc/fstab						#/dev/sdx
	echo "$boot		/boot		ext4		defaults        0 2" >> /etc/fstab						#/dev/sdx
	nano -w /etc/fstab
	
	echo 'hostname="gentoo-pc"' >> /etc/conf.d/hostname
	emerge --ask --noreplace net-misc/netifrc
#	nano -w /etc/conf.d/net; fi	# config_eth0="dhcp"
#	cd /etc/init.d
#	ln -s net.lo net.eth0
#	rc-update add net.eth0 default
	passwd
#	nano -w /etc/rc.conf
#	nano -w /etc/conf.d/keymaps
#	nano -w /etc/conf.d/hwclock
	emerge --ask app-admin/sysklogd
	rc-update add sysklogd default
#	if [ $1 == '1' ]; then rc-update add sshd default
	emerge --ask net-misc/dhcpcd
#	if [ $1 == '1' ]; then emerge --ask net-wireless/iw net-wireless/wpa_supplica



	echo "##########################################"
	echo "now 9"
	exit
fi

################################	9
if [ $1 == '9' ]; then

	emerge --ask --verbose sys-boot/grub:2
	grub-install $disk
	grub-mkconfig -o /boot/grub/grub.cfg

#	emerge --ask sys-boot/syslinux
#	syslinux --install $boot 

	echo "##########################################"
	echo "now 10"
fi


################################	10
if [ $1 == '10' ]; then

	lsmod > /lsmod.txt

	echo "##########################################"
	echo "now exit"
	echo "now 11"
	
fi

################################	11
if [ $1 == '11' ]; then
	cd
	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo
	reboot
	exit
fi


if [ $1 == '20' ]; then
	emerge --ask-enter-invalid x11-base/xorg-server
	etc-update
	source /etc/profile
fi
if [ $1 == '21' ]; then	emerge --ask-enter-invalid x11-wm/i3; fi
if [ $1 == '22' ]; then	echo "exec i3" >> ~/.xinitrc; fi
if [ $1 == '23' ]; then	emerge --ask-enter-invalid x11-terms/xterm; fi
if [ $1 == '24' ]; then	emerge --ask-enter-invalid x11-misc/i3status; fi
if [ $1 == '25' ]; then	emerge --ask-enter-invalid x11-misc/i3lock; fi

#	etc-update



if [ $1 == '26' ]; then
	emerge --ask-enter-invalid media-gfx/feh
	emerge --ask-enter-invalid app-misc/mc
	emerge --ask-enter-invalid app-misc/screenfetch
#	emerge --ask-enter-invalid sys-apps/lm-sensors
	emerge --ask-enter-invalid sys-process/htop
#	emerge --ask-enter-invalid app-admin/conky
	emerge --ask-enter-invalid sys-power/cpupower	#cpupower frequency-set -g powersave
	emerge --ask-enter-invalid x11-apps/xbacklight	#xbacklight -set 50

fi

#user
if [ $1 == '29' ]; then
	emerge --ask app-admin/sudo
	useradd -m -G users,wheel,audio -s /bin/bash $USER
	echo "exec i3" >> /home/$USER/.xinitrc
	echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
	passwd $USER
#	passwd -l root
fi

#wifi
if [ $1 == '30' ]; then
	emerge --ask-enter-invalid net-wireless/iw net-wireless/wpa_supplicant
fi
#wifi
#wpa_passphrase <ssid> [passphrase] > /etc/wpa_supplicant/wpa_supplicant.conf
#rc-update add wpa_supplicant default
#/etc/init.d/wpa_supplicant start


if [ $1 == '31' ]; then
	wget $SERVERURL/config
	mv ~/.config/i3/config ~/.config/i3/config.old
	mv ~/config ~/.config/i3/config
fi
if [ $1 == '32' ]; then emerge --ask pulseaudio; fi
if [ $1 == '33' ]; then emerge --ask alsa-mixer; fi
if [ $1 == '34' ]; then emerge --ask alsa-utils; fi

if [ $1 == '27' ]; then
	etc-update
	emerge --ask www-client/firefox
fi

if [ $1 == '28' ]; then
	etc-update
	emerge --ask app-emulation/virtualbox
fi

if [ $1 == '99' ]; then
	mv qdgentoo.sh qdgentoo.old
	wget $SERVERURL/qdgentoo.sh
	chmod +x qdgentoo.sh
fi


exit




