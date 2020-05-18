#! /bin/bash

USER='user'

GITURL="https://raw.githubusercontent.com/l3f7s1d3/qdgentoo/master/"

kernel='=sys-kernel/gentoo-sources-5.6.13 ~amd64'
virtualbox='=app-emulation/virtualbox-6.1.6 ~amd64'
virtualbox_modules='=app-emulation/virtualbox-modules-6.1.6 ~amd64'

aes_yesno=0	#1=no 0=yes

case 2 in
	"1")
		disk='/dev/sda'
		boot='/dev/sda1'
		root='/dev/sda2'
		home='/dev/sda3';;
	"2")
		disk='/dev/nvme0n1'
		boot='/dev/nvme0n1p1'
		root='/dev/nvme0n1p2'
		home='/dev/nvme0n1p3';;
	*) exit;;
esac


banner(){
	clear
	echo "###########################################################################"
	echo "#                                                                         #"
	echo "#                                 qdgentoo                                #"
	echo "#                                                                         #"
	echo "###########################################################################"
	echo "$kernel"
	echo "$virtualbox"
	echo "$virtualbox_modules"
	echo "###########################################################################"
	echo "#                                    #                                    #"
	echo "#  0   makefs                        #  20 xorg-server                    #"
	echo "#                                    #  21 i3                             #"
	echo "#  1   do in chroot                  #  22 ~/.xinitrc                     #"
	echo "#  2   @world                        #  23 xterm                          #"
	echo "#  3   locale                        #  24 i3status                       #"
	echo "#  4   env-update                    #  25 i3lock                         #"
	echo "#  5   gentoo-sources                #  26 stuff                          #"
	echo "#  6   pciutils                      #  27 firefox                        #"
	echo "#  7   genkernel                     #  28 virtualbox                     #"
	echo "#                                    #  29 makeuser                       #"
	echo "#  8   fstab & Stuff                 #  30 wifi                           #"
	echo "#                                    #  31 i3config                       #"
	echo "#  9   grub                          #  32 audio                          #"
	echo "#                                    #  33 powersave                      #"
	echo "#  10  reboot                        #  34                                #"
	echo "#                                    #  35 thunar                         #"
	echo "#                                    #  36 file-roller                    #"
	echo "#  13  genkernel_update              #  37 mc                             #"
	echo "#  14  genkernel_aes_update          #  38 no root xorg-server            #"
	echo "#  15  nano make.conf                #  39 cdrtools                       #"
	echo "#  99. update                        #                                    #"
	echo "###########################################################################"
	echo ""
}

################################	0
makefs(){
	cfdisk $disk
	sleep 1
	mkfs.ext4 $boot
	mkfs.ext4 $root
	mkfs.ext4 $home
	mount $root /mnt/gentoo
	makefs_2

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
	makefs_2
}

makefs_2(){
	cp /root/stage3.tar.xz /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo
#	wget -O stage3.tar.xz $STAGE3URL

	tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner
	#wget $GITURL/make.conf -o /mnt/gentoo/etc/portage/make.conf
	nano -w /mnt/gentoo/etc/portage/make.conf		
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
		
	fstab_stuff_2
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

	fstab_stuff_2
}

fstab_stuff_2(){
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
reboot_now(){
	cd
	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo
	reboot
}

################################	13
genkernel_update(){
	emerge --sync
	echo "$kernel" >> /etc/portage/package.accept_keywords
	emerge --ask sys-kernel/gentoo-sources
	eselect kernel list
	echo "eselect kernel set X"
	echo "genkernel --menuconfig all"
}

################################	14
genkernel_aes_update(){
	emerge --sync
	echo "$kernel" >> /etc/portage/package.accept_keywords
	emerge --ask sys-kernel/gentoo-sources
	eselect kernel list
	echo "eselect kernel set X"
	echo "genkernel --luks --lvm --no-zfs --menuconfig all"
}


case $1 in
	"0")
		if aes_yesno; then
			makefs
		else
			makefs_aes
		fi;;
	"1") do_in_chroot;;
	"2") at_world;;
	"3") make_locale;;
	"4") env_update;;
	"5") gentoo_sources;;
	"6") pci_utils;;
	"7") 
		if aes_yesno; then
			gentoo_genkernel
		else
			gentoo_genkernel_aes
		fi;;
	"8")
		if aes_yesno; then
			fstab_stuff
		else
			fstab_stuff_aes
		fi;;
	"9")
		if aes_yesno; then
			install_grub
		else
			install_grub_aes
		fi;;
	"10") reboot_now;;
	
	"13") genkernel_update ;;
	"14") genkernel_aes_update ;;
	"15") nano -w /etc/portage/make.conf ;;



	"20") #xorg
		emerge --ask x11-base/xorg-server --autounmask-write; source /etc/profile
		etc-update
		emerge --ask x11-base/xorg-server; source /etc/profile;;
	"21") emerge --ask x11-wm/i3;;
	"22") echo "exec i3" >> ~/.xinitrc;;
	"23") emerge --ask x11-terms/xterm;;
	"24") emerge --ask x11-misc/i3status;;
	"25") emerge --ask x11-misc/i3lock;;
	"26") emerge media-gfx/feh app-misc/screenfetch sys-apps/lm-sensors x11-apps/xbacklight sys-process/htop;;
	"27") emerge --ask www-client/firefox;;
	"28") 
		echo "$virtualbox" >> /etc/portage/package.accept_keywords
		echo "$virtualbox_modules" >> /etc/portage/package.accept_keywords
		emerge --ask app-emulation/virtualbox
		modprobe vboxdrv;;
	"29") #user
		emerge --ask app-admin/sudo
		useradd -m -G users,wheel,audio -s /bin/bash $USER
		echo "exec i3" >> /home/$USER/.xinitrc
		echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
		passwd $USER
#		passwd -l root
		cp qdgentoo.sh /home/$USER/qdgentoo.sh
		emerge xrandr
		echo "user:" $USER;;
	"30") emerge --ask net-wireless/iw net-wireless/wpa_supplicant;;
	"31")
		wget $GITURL/config
		mv ~/.config/i3/config ~/.config/i3/config.old
		mv ~/config ~/.config/i3/config;;
	"32")  emerge pulseaudio; emerge alsa-mixer; emerge alsa-utils;;
	"33")
		emerge sys-power/cpupower
		echo '#!/bin/bash' > /etc/local.d/powersave.start
		echo 'cpupower frequency-set -g powersave' >> /etc/local.d/powersave.start
		chmod +x /etc/local.d/powersave.start
		rc-update add local default;;
	"35") emerge --ask thunar; ;;
	"36") emerge --ask file-roller;;
	"37") emerge --ask app-misc/mc;;
	"38")
		USE="-suid" emerge --update --deep --newuse --verbose --ask xorg-server
		echo 'SUBSYSTEM=="input", ACTION=="add", GROUP="input"' >> /etc/udev/rules.d/99-dev-input-group.rules
		usermod -a -G video $USER
		usermod -a -G input $USER;;
	"39") emerge --ask cdrtools;;

	"99")
		mv qdgentoo.sh qdgentoo.old
		wget $GITURL/qdgentoo.sh
		chmod +x qdgentoo.sh;;
	*) banner;;
esac
exit
