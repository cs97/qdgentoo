#! /bin/bash

USER='user'

hostname='gentoo-pc'

timezone='Europe/Berlin'

locale='
#en_US ISO-8859-1
\n#en_US.UTF-8 UTF-8
\n
\nde_DE ISO-8859-1
\nde_DE@euro ISO-8859-15
\nde_DE.UTF-8 UTF-8'

german=true

# disk encryption
aes_yesno=false

# false=automode true=cfdsik
use_cfdisk=false

simple_mode=true

make_conf='https://raw.githubusercontent.com/cs97/qdgentoo/master/etc/portage/make.conf'

kernel='=sys-kernel/gentoo-sources-6.2.0 ~amd64'

#GRUB_CMDLINE_LINUX_DEFAULT='GRUB_CMDLINE_LINUX_DEFAULT="modprobe.blacklist=nouveau quiet splash"'
GRUB_CMDLINE_LINUX_DEFAULT='GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"'

#echo 0 > /sys/devices/system/cpu/cpufreq/boost

# disk layout
disk='/dev/nvme0n1'
boot=$disk'p1'
root=$disk'p2'
home=$disk'p3'

#disk='/dev/sda'
#boot=$disk'1'
#root=$disk'2'
#home=$disk'3'

# root in GiB -1GiB
root_size=100


banner_head(){
	clear
	echo
	echo ""
	echo -e "\t\tqdgentoo installer\n"
	echo -e "\trun on" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
	echo -e "\tuser: $USER"
	echo -e "\tdisk: $disk"
	echo -e "\tdisk encryption: $aes_yesno"
	echo -e "\tload_makeconf: $make_conf"
	echo -e "\tuse cfdisk: $use_cfdisk\n"

}

banner(){
	banner_head
	echo -e "\t0  makefs"
	echo -e "\t1. do in chroot"
	echo -e "\t2. @world"
	echo -e "\t3. locale"
	echo -e "\t4. env-update"
	echo -e "\t5. gentoo-sources"
	echo -e "\t6. pciutils"
	echo -e "\t7. genkernel"
	echo -e "\t8. fstab & Stuff"
	echo -e "\t9. grub"
	echo -e "\t10.umount all\n"
	echo -e "\t11.mount_again"
	echo -e "\t12.first_boot"
	echo -e ""
	echo -e "\t14.add user"	
	echo -e "\t15.wayland + sway"
	echo -e "\t16.install_audio"
	echo -e "\t17.install_wifi"
	echo -e "\t18.install_amdgpu"
	echo -e "\t19.install_nvidia"
	echo -e "\t20.install_tools\n"
	echo -e "\t21.my_config\n"
	echo -e "\t99. update\n"
}
simple_banner(){
	banner_head
	echo -e "\tinstall \t\tinstall base system"
	echo -e "\tfirst_boot \t\trun on first boot"
	echo -e "\tadd_user \t\tadd user"
	echo -e "\tinstall_sway \t\tinstall sway desktop"
	echo -e "\tinstall_wifi"
	echo -e "\tupdate \t\t\tupdate installer"

}
################################	0
makefs(){
	[ -d /sys/firmware/efi ] && {
		parted $disk --script mklabel gpt
	} || {
		parted $disk --script mklabel msdos
	}
	
	[ $use_cfdisk = true ] && {
		cfdisk $disk
	} || {
		#EFI
		parted $disk --script mkpart primary fat32 1MiB 1024MiB
		parted $disk --script mkpart primary ext4 1024MiB $root_size'GiB'
		parted $disk --script mkpart primary ext4 $root_size'GiB' 100%
	}
	sleep 1
	mkfs.fat -F 32 $boot
	mkfs.ext4 $root
	mkfs.ext4 $home
	mount $root /mnt/gentoo
	makefs_2

}
################################	0.1
makefs_aes(){

	[ -d /sys/firmware/efi ] && {
		parted /dev/$disk --script mklabel gpt
	} || {
		parted /dev/$disk --script mklabel msdos
	}
	
	[ $use_cfdisk = true ] && {
		cfdisk $disk
	} || {
		parted $disk --script mkpart primary fat32 1MiB 1024MiB
		parted $disk --script mkpart primary ext4 1024MiB 100%
	}
		
	sleep 1
	mkfs.fat -F 32 $boot
	modprobe dm-crypt
	cryptsetup luksFormat --type luks1 $root
	cryptsetup luksOpen $root lvm
	lvm pvcreate /dev/mapper/lvm
	vgcreate vg0 /dev/mapper/lvm
	lvcreate -L $root_size'G' -n root vg0
	lvcreate -l 100%FREE -n home vg0
	mkfs.ext4 /dev/mapper/vg0-root
	mkfs.ext4 /dev/mapper/vg0-home
	mount /dev/mapper/vg0-root /mnt/gentoo
	makefs_2
}

makefs_2(){
	[ -d stage3* ] || cp stage3* /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo
	[ -d stage3* ] && links https://www.gentoo.org/downloads/
	tar xpvf stage3*.tar.xz --xattrs-include='*.*' --numeric-owner
	#[ $load_makeconf = true ] && wget https://raw.githubusercontent.com/cs97/qdgentoo/master/conf/make.conf -O /mnt/gentoo/etc/portage/make.conf
	wget $make_conf -O /mnt/gentoo/etc/portage/make.conf
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
	cp ~/qdgentoo.sh /mnt/gentoo/root/qdgentoo.sh
	[ $simple_mode = false ] && chroot /mnt/gentoo /bin/bash
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
}
################################	2
at_world(){
	#emerge --ask --verbose --update --deep --newuse @world
	emerge --verbose --update --deep --newuse @world			

}
################################	3
make_locale(){
#	portageq envvar ACCEPT_LICENSE @FREE
	#echo "Europe/Berlin" > /etc/timezone
	echo $timezone > /etc/timezone	
	emerge --config sys-libs/timezone-data
	#echo "en_US ISO-8859-1" >> /etc/locale.gen
	#echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	#[ $german = true ] && {
	#	echo "de_DE ISO-8859-1" >> /etc/locale.gen
	#	echo "de_DE@euro ISO-8859-15" >> /etc/locale.gen
	#	echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
	#}
	echo -e $locale >> /etc/locale.gen	

	[ $simple_mode = false ] && nano -w /etc/locale.gen
	locale-gen
	clear
	eselect locale set 6
	eselect locale list
	}
################################	4
env_update(){
	env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
	echo "### etc-update ###"
	etc-update
}
################################	5
gentoo_sources(){
	echo "$kernel" > /etc/portage/package.accept_keywords/kernel
	echo "sys-kernel/gentoo-sources experimental" >> /etc/portage/package.use/kernel
	#emerge --ask sys-kernel/gentoo-sources
	emerge sys-kernel/gentoo-sources
	etc-update
}
################################	6
pci_utils(){
	emerge sys-apps/pciutils
	etc-update
}
################################	7
gentoo_genkernel(){
	mkdir /etc/portage/package.license
	echo "sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE" > /etc/portage/package.license/firmware
	#emerge --ask genkernel
	emerge genkernel
	eselect kernel set 1
	etc-update
	[ $simple_mode = true ] && {
		[ $aes_yesno = true ] && genkernel --luks --lvm --no-zfs all || genkernel all
	} || {
		[ $aes_yesno = true ] && genkernel --luks --lvm --no-zfs --menuconfig all || genkernel --menuconfig all
	}
}
################################	8
fstab_stuff(){
	[ $aes_yesno = true ] && {
		echo "/dev/mapper/vg0-root		/		ext4		defaults	0 0" >> /etc/fstab
		echo "$boot		/boot		vfat		defaults        0 0" >> /etc/fstab
		echo "/dev/mapper/vg0-home		/home		ext4		defaults	0 0" >> /etc/fstab
	} || {
		echo "$root		/		ext4		defaults        0 0" >> /etc/fstab
		echo "$boot		/boot		vfat		defaults	0 0" >> /etc/fstab
		echo "$home		/home		ext4		defaults	0 0" >> /etc/fstab
	}
	
	echo "tmpfs		/tmp		tmpfs		size=4G		0 0" >> /etc/fstab
	echo "tmpfs		/run		tmpfs		size=100M	0 0" >> /etc/fstab
	
	[ $simple_mode = false ] && nano -w /etc/fstab
	passwd
	emerge app-admin/sysklogd net-misc/dhcpcd net-misc/chrony
	#[ $aes_yesno = true ] && emerge --ask sys-fs/lvm2
	[ $aes_yesno = true ] && emerge sys-fs/lvm2

}
################################	9.2
install_grub_efi(){
	[ -d /sys/firmware/efi ] && echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	[ $aes_yesno = true ] && echo "sys-boot/boot:2 device-mapper" >> /etc/portage/package.use/sys-boot
	#emerge --ask --verbose sys-boot/grub:2
	emerge --verbose sys-boot/grub:2
	[ $aes_yesno = true ] && echo 'GRUB_CMDLINE_LINUX="dolvm crypt_root='$root' root=/dev/mapper/vg0-root"' >> /etc/default/grub
	echo "$GRUB_CMDLINE_LINUX_DEFAULT" >> /etc/default/grub
	echo "#GRUB_GFXMODE=1920x1080x32" >> /etc/default/grub
	echo '#GRUB_BACKGROUND="/boot/grub/wow.png"' >> /etc/default/grub
	[ $simple_mode = false ] && nano /etc/default/grub
	[ -d /sys/firmware/efi ] && grub-install --target=x86_64-efi --efi-directory=/boot || grub-install $disk

	grub-mkconfig -o /boot/grub/grub.cfg
}
################################	10
umount_all(){
	cd /
	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo
	echo "pls reboot"
}
################################	11
mount_again(){
	mkdir /mnt/gentoo
	sleep 1
	mount $root /mnt/gentoo
	sleep 1
	mount $boot /mnt/gentoo/boot
	sleep 1
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
	chroot /mnt/gentoo /bin/bash
}
################################	12
first_boot(){
	[ $german = true ] && {
		localectl set-locale LC_MESSAGES=de_DE.utf8 LANG=de_DE.UTF-8 
		localectl set-keymap de
	}

	[ -d /run/systemd/system ] && {
		hostnamectl hostname $hostname	
		systemctl enable --now dhcpcd
		#systemctl enable chronyd.service
		systemctl enable --now systemd-timesyncd.service
	} || {
		echo 'hostname="'$hostname'"' > /etc/conf.d/hostname
		rc-update add dhcpcd default
		rc-service dhcpcd start
		rc-update add chronyd default
	}
}

################################  install base system
install_base_system(){
	makefs
	chroot /mnt/gentoo /bin/bash -c "/root/qdgentoo.sh 1to9"
	umount_all
	reboot
}
do_1_to_9(){
	do_in_chroot
	at_world
	make_locale
	env_update
	gentoo_sources
	pci_utils
	gentoo_genkernel
	fstab_stuff
	install_grub_efi
}

################################	14
add_user(){
	emerge --ask app-admin/sudo
	useradd -m -G users,wheel,audio -s /bin/bash $USER
	echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
	passwd $USER
#	passwd -l root
	cp qdgentoo.sh /home/$USER/
	usermod -a -G video $USER
	usermod -a -G input $USER
}
################################	15
install_wayland_sway(){
	echo "gui-libs/wlroots X" >> /etc/portage/package.use/wm
	echo "gui-wm/sway X wallpapers" >> /etc/portage/package.use/wm
	emerge --ask dev-libs/wayland gui-wm/sway dev-libs/light gui-apps/swaylock x11-terms/alacritty
	[ -d /run/systemd/system ] || rc-update add seatd default
	[ $simple_mode = true ] && install_audio
}
################################	16
install_audio(){

	[ whoami == root ] && {
		echo "media-video/pipewire pipewire-alsa sound-server" >> /etc/portage/package.use/pipewire
		emerge --ask alsa-utils pipewire
		sudo -u $USER /bin/bash -c "qdgentoo.sh install_audio"
	} || {
		[ -d /run/systemd/system ] && {
			systemctl --user enable --now pipewire.socket
			systemctl --user enable --now pipewire.service
			systemctl --user enable --now wireplumber.service
			systemctl --user mask pulseaudio.socket pulseaudio.service
			systemctl --user enable --now pipewire-pulse.service
		} || {
			rc-update add alsasound boot
		}
	}
}

################################	17
install_wifi(){
	echo ">=net-wireless/wpa_supplicant-2.10-r1 dbus" >> /etc/portage/package.use/wifi
	#emerge --ask net-wireless/wpa_supplicant
	emerge --ask networkmanager
	#emerge --ask nm-applet
	systemctl enable NetworkManager
	systemctl start NetworkManager
	}
################################	18
install_amdgpu(){
	emerge --ask xf86-video-amdgpu
}
################################	19
install_nvidia(){
	echo "x11-drivers/nvidia-drivers NVIDIA-r2 ~amd64" >> /etc/portage/package.license/firmware
	echo "dev-util/nvidia-cuda-toolkit NVIDIA-CUDA" >> /etc/portage/package.license/firmware
	echo ">=x11-drivers/nvidia-drivers-515.49.06" >> /etc/portage/package.accept_keywords/nvidia
	echo "x11-drivers/nvidia-drivers -tools" >> /etc/portage/package.use/nvidia
	emerge --ask x11-drivers/nvidia-drivers
}
################################	20
install_tools(){
	#echo "xfce-base/thunar udisks" > /etc/portage/package.use/thunar
	#emerge --ask xfce-base/thunar app-arch/file-roller
	emerge --ask app-editors/vim
	emerge --ask sys-process/htop
	emerge --ask app-misc/neofetch
	emerge --ask dev-lang/rust
	emerge --ask dev-vcs/git
	emerge --ask sys-apps/lm-sensors
	#emerge --ask sys-power/cpupower

	#gut
	#wget https://raw.githubusercontent.com/cs97/qdgentoo/master/shell-script/gentoo-update-tool.sh
	#mv gentoo-update-tool.sh /usr/bin/gut
	#chmod +x /usr/bin/gut

}
################################	21
my_config(){
	emerge --ask x11-terms/alacritty

	mkdir .config
	mkdir .config/sway
	mv .config/sway/config .config/sway/config.old

	#sway .config
	wget https://raw.githubusercontent.com/cs97/qdgentoo/master/conf/sway-config
	mv sway-config .config/sway/config

	#sway status
	git clone https://github.com/cs97/rusty-sway-status
	cd rusty-sway-status
	cargo build --release
	cp target/release/status /usr/bin/status
	cd ..

	#.bashrc
	mv .bashrc .bashrc.old
	wget https://raw.githubusercontent.com/cs97/qdgentoo/master/conf/.bashrc
}

################################	22
#razer_blade_14(){
	#runsway
	#wget https://raw.githubusercontent.com/cs97/My-Razer-Blade-14-2021/main/runsway
	#mv runsway.sh /usr/bin/runsway
	#chmod +x /usr/bin/runsway

	#powermode
	#wget https://raw.githubusercontent.com/cs97/qdgentoo/master/shell-script/powermode.sh
	#mv powermode.sh /usr/bin/powermode
	#chmod +x /usr/bin/powermode
#}
################################	install desktop
install_sway(){
	install_wayland_sway
	emerge app-editors/vim dev-vcs/git dev-lang/rust sys-process/htop sys-apps/lm-sensors	
}
################################	99
update_installer(){
	mv qdgentoo.sh qdgentoo.old
	wget https://raw.githubusercontent.com/cs97/qdgentoo/master/qdgentoo.sh
	chmod +x qdgentoo.sh
	chmod -x qdgentoo.old
}

################################	switch
[ "$EUID" -ne 0 ] && echo "Please run as root" #&& exit


[ $simple_mode = true ] && {
	case $1 in
		"install") install_base_system;;	#base system install
		"first_boot") first_boot;;
		"add_user") add_user;;
		"install_sway") install_wayland_sway;;
		"install_wifi") install_wifi;;
		#"install_audio") install_audio;;

		"1to9") do_1_to_9;;
		"update") update_installer;;
		*) simple_banner;;
	esac
} || {
	case $1 in
		"0") [ $aes_yesno = true ] && makefs_aes || makefs;;
		"1") do_in_chroot;;
		"2") at_world;;
		"3") make_locale;;
		"4") env_update;;
		"5") gentoo_sources;;
		"6") pci_utils;;
		"7") gentoo_genkernel;;
		"8") fstab_stuff;;
		"9") install_grub_efi;;
		"10") umount_all;;
		"11") mount_again;;
		"12") first_boot;;

		"14") add_user;;
		"15") install_wayland_sway;;
		"16") install_audio;;
		"17") install_wifi;;
		"18") install_amdgpu;;
		"19") install_nvidia;;
		"20") install_tools;;
		"21") my_config;;
		"99") update_installer;;
		*) banner;;
	esac
}

exit
