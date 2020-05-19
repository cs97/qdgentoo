#! /bin/bash

USER='user'

GITURL="https://raw.githubusercontent.com/l3f7s1d3/qdgentoo/master/"

kernel='=sys-kernel/gentoo-sources-5.6.13 ~amd64'
virtualbox='=app-emulation/virtualbox-6.1.6 ~amd64'
virtualbox_modules='=app-emulation/virtualbox-modules-6.1.6 ~amd64'

aes_yesno=true
efi_yesno=true

if [ $efi_yesno = true ]; then
	mk_boot_fs="mkfs.fat -F 32"
else
	mk_boot_fs="mkfs.ext4"
fi

# 1=bios/sdx 2=bios/nvme0n1 3=efi/sdx 4=efi/nvme0n1
case 4 in
	"1")	#DOS					#no aes		# aes
		disk='/dev/sda'
		boot='/dev/sda1'	# 512M		(boot)		(boot)
		root='/dev/sda2'	# 25G		(root)		(lvm)
		home='/dev/sda3';;	# 100%FREE	(home)		(x)
	"2")
		disk='/dev/nvme0n1'
		boot='/dev/nvme0n1p1'
		root='/dev/nvme0n1p2'
		home='/dev/nvme0n1p3';;
		
	"3")	# GPT					#no aes		# aes
		disk='/dev/sda'		
		uefi='/dev/sda1'	# 2M		(bootloader)	(bootloader)
		boot='/dev/sda2'	# 128M		(fat32 UEFI)	(fat32 UEFI)
		root='/dev/sda3'	# 25G		(root)		(lvm)
		home='/dev/sda4';;	# 100%FREE	(home)		(x)
	"4")	# GPT
		disk='/dev/nvme0n1'		
		uefi='/dev/nvme0n1p1'	# 2M		(bootloader)	(bootloader)
		boot='/dev/nvme0n1p2'	# 128M		(fat32 UEFI)	(fat32 UEFI)
		root='/dev/nvme0n1p3'	# 25G		(root)		(lvm)
		home='/dev/nvme0n1p4';;	# 100%FREE	(home)		(x)
	*) exit;;
esac


banner(){
	clear
	echo "###########################################################################"
	echo "#                                                                         #"
	echo "#                                 qdgentoo                                #"
	echo "#                                                                         #"
	echo "###########################################################################"
	echo "run on" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
	echo "$kernel"
	echo "$virtualbox"
	echo "$virtualbox_modules"
	echo "###########################################################################"
	echo "#                                    #                                    #"
	echo "#  0   makefs                        #  20 xorg-server                    #"
	echo "#  1   do in chroot                  #  21 i3                             #"
	echo "#  2   @world                        #  22 ~/.xinitrc                     #"
	echo "#  3   locale                        #  23 xterm                          #"
	echo "#  4   env-update                    #  24 i3status                       #"
	echo "#  5   gentoo-sources                #  25 i3lock                         #"
	echo "#  6   pciutils                      #  26 stuff                          #"
	echo "#  7   genkernel                     #  27 firefox                        #"
	echo "#  8   fstab & Stuff                 #  28 virtualbox                     #"
	echo "#  9   grub                          #  29 makeuser                       #"
	echo "#  10  reboot                        #  30 wifi                           #"
	echo "#                                    #  31 i3config                       #"
	echo "#                                    #  32 audio                          #"
	echo "#                                    #  33 powersave                      #"
	echo "#                                    #  34                                #"
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
	$mk_boot_fs $boot
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
	$mk_boot_fs $boot
	modprobe dm-crypt
	#cryptsetup luksFormat -c aes-xts-plain64:sha256 -s 256 $root
	cryptsetup luksFormat --type luks1 $root
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
	echo "tmpfs		/tmp		tmpfs		size=4G		0 0" >> /etc/fstab
	echo "tmpfs		/run		tmpfs		size=100M	0 0" >> /etc/fstab

		
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
	echo "tmpfs		/tmp		tmpfs		size=4G		0 0" >> /etc/fstab
	echo "tmpfs		/run		tmpfs		size=100M	0 0" >> /etc/fstab


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
################################	9.2
install_grub_efi(){
	echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	emerge --ask --verbose sys-boot/grub:2
	grub-install --target=x86_64-efi --efi-directory=/boot
	grub-mkconfig -o /boot/grub/grub.cfg
}
################################	9.3
install_grub_aes_efi(){
	echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	echo "sys-boot/boot:2 device-mapper" >> /etc/portage/package.use/sys-boot
	emerge --ask --verbose sys-boot/grub:2
	echo 'GRUB_CMDLINE_LINUX="dolvm crypt_root='$root' root=/dev/mapper/vg0-root"' >> /etc/default/grub
	nano /etc/default/grub	
	grub-install --target=x86_64-efi --efi-directory=/boot
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

case $1 in
	"0")
		if [ $aes_yesno = false ]; then
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
		if [ $aes_yesno = false ]; then
			gentoo_genkernel
		else
			gentoo_genkernel_aes
		fi;;
	"8")
		if [ $aes_yesno = false ]; then
			fstab_stuff
		else
			fstab_stuff_aes
		fi;;
	"9")
		if [ $aes_yesno = false ] && [ $efi_yesno = false ]; then
			install_grub
		elif [ $aes_yesno = false ] && [ $efi_yesno = true ]; then
			install_grub_efi
		elif [ $aes_yesno = true ] && [ $efi_yesno = true ]; then
			install_grub_aes_efi
		else
			install_grub_aes
		fi;;
	"10") reboot_now;;
	
	"13") genkernel_update ;;
	"14") genkernel_aes_update ;;
	"15") nano -w /etc/portage/make.conf ;;



	"20") xorg_install;;
	"21") emerge --ask x11-wm/i3;;
	"22") echo "exec i3" >> ~/.xinitrc;;
	"23") emerge --ask x11-terms/xterm;;
	"24") emerge --ask x11-misc/i3status;;
	"25") emerge --ask x11-misc/i3lock;;
	"26") emerge media-gfx/feh app-misc/screenfetch sys-apps/lm-sensors x11-apps/xbacklight sys-process/htop;;
	"27") emerge --ask www-client/firefox;;
	"28") virtualbox_install;;
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
	"33") cpupower_install;;
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
