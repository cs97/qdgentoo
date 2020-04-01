#! /bin/bash

SERVERURL="https://raw.githubusercontent.com/l3f7s1d3/qdgentoo/master/"
STAGE=''
#STAGE3URL='distfiles.gentoo.org/releases/amd64/autobuilds/20200205T214502Z/stage3-amd64-20200205T214502Z.tar.xz'
USER='user'
kernel='=sys-kernel/gentoo-sources-5.6.0 ~amd64'
disk='/dev/sda'
boot='/dev/sda1'
root='/dev/sda2'
home='/dev/sda3'

banner(){
	clear
	echo "###########################################################################"
	echo "#                                                                         #"
	echo "#                                 qdgentoo                                #"
	echo "#                                                                         #"
	echo "###########################################################################"
	echo "#                                    #                                    #"
	echo "# 0.   makefs                        # 20. xorg-server                    #"
	echo "# 0.1. makefs (AES)                  # 21. i3                             #"
	echo "# 1.   do in chroot                  # 22. ~/.xinitrc                     #"
	echo "# 2.   @world                        # 23. xterm                          #"
	echo "# 3.   locale                        # 24. i3status                       #"
	echo "# 4.   env-update                    # 25. i3lock                         #"
	echo "# 5.   gentoo-sources                # 26. stuff                          #"
	echo "# 6.   pciutils                      # 27. firefox                        #"
	echo "# 7.   genkernel                     # 28. virtualbox                     #"
	echo "# 7.1. genkernel (AES)               # 29. makeuser                       #"
	echo "# 8.   fstab & Stuff                 # 30. wifi                           #"
	echo "# 8.1. fstab & Stuff (AES)           # 31. i3config                       #"
	echo "# 9.   grub                          # 32. audio                          #"
	echo "# 9.1. grub (AES)                    # 33. powersave                      #"
	echo "# 10.  lsmod > /lsmod.txt            # 34.                                #"
	echo "# 11.  reboot                        # 35. thunar                         #"
	echo "#                                    # 36. file-roller                    #"
	echo "#                                    # 37. mc                             #"
	echo "#                                    # 38. no root xorg-server            #"
	echo "# 99. update                         # 39. cdrtools                       #"
	echo "###########################################################################"
	echo ""
	exit
}

################################	0
makefs(){
	cfdisk $disk
	sleep 1
	mkfs.ext4 $boot
	mkfs.ext4 $root
	mkfs.ext4 $home
	mount $root /mnt/gentoo
	cp /root/stage3.tar.xz /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo
#	wget -O stage3.tar.xz $STAGE3URL
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
	cp ~/qdgentoo.sh /mnt/gentoo/root/qdgentoo.sh
	chroot /mnt/gentoo /bin/bash
}

################################	0.1
makefs_aes(){
	cd /mnt/gentoo
	cfdisk $disk
	sleep 1
	mkfs.ext4 $boot
	modprobe dm-crypt
	cryptsetup luksFormat -c aes-xts-plain64:sha256 -s 256 $root
	cryptsetup luksOpen $root lvm
	lvm pvcreate /dev/mapper/lvm
	vgcreate vg0 /dev/mapper/lvm
	lvcreate -L 25G -n root vg0
#	lvcreate -L 40G -n var vg0
	lvcreate -l 100%FREE -n home vg0
	mkfs.ext4 /dev/mapper/vg0-root
#	mkfs-ext4 /dev/mapper/vg0-var
	mkfs.ext4 /dev/mapper/vg0-home
#	mkdir /mnt/gentoo
	mount /dev/mapper/vg0-root /mnt/gentoo
#	mkdir /mnt/gentoo/var
#	mount /dev/mapper/vg0-var /mnt/gentoo/var
	cp /root/stage3.tar.xz /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo

#	wget -O stage3.tar.xz $STAGE3URL
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
	chroot /mnt/gentoo /bin/bash
}

################################	1
do_in_chroot(){
	source /etc/profile
	export PS1="(chroot) ${PS1}"
	mount $boot /boot
	emerge-webrsync
	emerge --sync
	clear

	eselect profile list
	echo "##########################################"
	echo "eselect profile set X"		#skipt
}

################################	2
at_world(){
	emerge --ask --verbose --update --deep --newuse @world			
}

################################	3
make_locale(){
#	portageq envvar ACCEPT_LICENSE @FREE
	echo "Europe/Berlin" > /etc/timezone
	emerge --config sys-libs/timezone-data
	nano -w /etc/locale.gen
#	 echo>>
	locale-gen
	clear
	eselect locale set 6
	eselect locale list
	echo "##########################################"
	echo "eselect locale set X"
	}

################################	4
env_update(){
	env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
	etc-update
}

################################	5
gentoo_sources(){
	echo "$kernel"
	echo "$kernel" > /etc/portage/package.accept_keywords
	emerge --ask sys-kernel/gentoo-sources
	etc-update
}

################################	6
pci_utils(){
	emerge --ask sys-apps/pciutils
#	lspci
	etc-update
}

################################	7
gentoo_genkernel(){
	emerge --ask genkernel
	etc-update
	genkernel --menuconfig all
}

################################	7.1
gentoo_genkernel_aes(){
	emerge --ask genkernel
	etc-update
	genkernel --luks --lvm --no-zfs --menuconfig all
}

################################	8
fstab_stuff(){
	etc-update
	emerge --ask sys-kernel/linux-firmware
	etc-update
	
	echo "$root		/root		ext4		defaults        0 1" >> /etc/fstab
	echo "$boot		/boot		ext4		defaults        0 2" >> /etc/fstab
	echo "$home		/home		ext4		defaults	0 3" >> /etc/fstab
		
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
	emerge --ask net-misc/dhcpcd
}

################################	8.1
fstab_stuff_aes(){
	etc-update
	emerge --ask sys-kernel/linux-firmware
	etc-update
	
	echo "/dev/mapper/vg0-root		/		ext4		defaults	0 1" >> /etc/fstab
	echo "$boot		/boot		ext4		defaults        0 2" >> /etc/fstab
	echo "/dev/mapper/vg0-home		/home		ext4		defaults	0 3" >> /etc/fstab
#	echo "tmpfs		/tmp		tmpfs		size=4Gb	0 0" >> /etc/fstab

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
	emerge --ask net-misc/dhcpcd
}

################################	9
install_grub(){
	emerge --ask --verbose sys-boot/grub:2
	grub-install $disk
	grub-mkconfig -o /boot/grub/grub.cfg
}

################################	9.1
install_grub_aes(){
	echo "sys-boot/boot:2 device-mapper" >> /etc/portage/package.use/sys-boot
	emerge --ask --verbose sys-boot/grub:2
	echo 'GRUB_CMDLINE_LINUX="dolvm crypt_root='$root' root=/dev/mapper/vg0-root"' >> /etc/default/grub
	nano /etc/default/grub	
	grub-install $disk
	grub-mkconfig -o /boot/grub/grub.cfg
}

################################	10
lsmod_lsmod.txt(){
	lsmod > /lsmod.txt
}

################################	11
reboot_now(){
	cd
	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo
	reboot
}


if [ -z "$1" ]; then
	banner
fi
if [ $1 == '0' ]; then
	makefs
fi
if [ $1 == '0.1' ]; then
	makefs_aes
fi
if [ $1 == '1' ]; then
	do_in_chroot
fi
if [ $1 == '2' ]; then
	at_world
fi
if [ $1 == '3' ]; then
	make_locale
fi
if [ $1 == '4' ]; then
	env_update
fi
if [ $1 == '5' ]; then
	gentoo_sources
fi
if [ $1 == '6' ]; then
	pci_utils
fi
if [ $1 == '7' ]; then
	gentoo_genkernel
fi
if [ $1 == '7.1' ]; then
	gentoo_genkernel_aes
fi
if [ $1 == '8' ]; then
	fstab_stuff
fi
if [ $1 == '8.1' ]; then
	fstab_stuff_aes
fi
if [ $1 == '9' ]; then
	install_grub
fi
if [ $1 == '9.1' ]; then
	install_grub_aes
fi
if [ $1 == '10' ]; then
	lsmod_lsmod.txt
fi
if [ $1 == '11' ]; then
	reboot_now
fi




if [ $1 == '20' ]; then
	emerge --ask-enter-invalid x11-base/xorg-server
	source /etc/profile
fi
if [ $1 == '21' ]; then	emerge --askx11-wm/i3; fi
if [ $1 == '22' ]; then	echo "exec i3" >> ~/.xinitrc; fi
if [ $1 == '23' ]; then	--ask emerge x11-terms/xterm; fi
if [ $1 == '24' ]; then	--ask emerge x11-misc/i3status; fi
if [ $1 == '25' ]; then	--ask emerge x11-misc/i3lock; fi



if [ $1 == '26' ]; then
	emerge media-gfx/feh
	emerge app-misc/mc
	emerge app-misc/screenfetch
#	emerge sys-apps/lm-sensors
	emerge sys-process/htop
#	emerge app-admin/conky
	emerge x11-apps/xbacklight	#xbacklight -set 50
fi
if [ $1 == '27' ]; then	emerge --ask www-client/firefox; fi
if [ $1 == '28' ]; then	emerge --ask app-emulation/virtualbox; fi

#user
if [ $1 == '29' ]; then
	emerge --ask app-admin/sudo
	useradd -m -G users,wheel,audio -s /bin/bash $USER
	echo "exec i3" >> /home/$USER/.xinitrc
	echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
	passwd $USER
#	passwd -l root
	cp qdgentoo.sh /home/$USER/qdgentoo.sh
fi


if [ $1 == '30' ]; then emerge --ask net-wireless/iw net-wireless/wpa_supplicant; fi
if [ $1 == '31' ]; then
	wget $SERVERURL/config
	mv ~/.config/i3/config ~/.config/i3/config.old
	mv ~/config ~/.config/i3/config
fi
if [ $1 == '32' ]; then
	emerge --ask pulseaudio
	emerge --ask alsa-mixer
	emerge --ask alsa-utils
fi
if [ $1 == '33' ]; then
	emerge sys-power/cpupower
	echo '#!/bin/bash' > /etc/local.d/powersave.start
	echo 'cpupower frequency-set -g powersave' >> /etc/local.d/powersave.start
	chmod +x /etc/local.d/powersave.start
	rc-update add local default
fi
if [ $1 == '35' ]; then emerge --ask thunar; fi
if [ $1 == '36' ]; then emerge --ask file-roller; fi
if [ $1 == '37' ]; then emerge --ask mc; fi

if [ $1 == '38' ]; then		#modprobe vboxdrv
	USE="-suid" emerge --update --deep --newuse --verbose --ask xorg-server
	echo 'SUBSYSTEM=="input", ACTION=="add", GROUP="input"' >> /etc/udev/rules.d/99-dev-input-group.rules
	usermod -a -G video $USER
	usermod -a -G input $USER
fi
if [ $1 == '39' ]; then emerge --ask cdrtools; fi



if [ $1 == '99' ]; then
	mv qdgentoo.sh qdgentoo.old
	wget $SERVERURL/qdgentoo.sh
	chmod +x qdgentoo.sh
fi


exit



