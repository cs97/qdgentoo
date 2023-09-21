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

#install_virtualbox-guest-additions
vbox=false

make_conf='https://raw.githubusercontent.com/cs97/qdgentoo/master/etc/portage/make.conf'

kernel='=sys-kernel/gentoo-sources-6.1.38 ~amd64'

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

# boot in MiB
# boot = boot_size - 1MiB
boot_size=512

# root in GiB 
# root = root_size - boot_size
root_size=100


banner_head(){
	clear
	echo
	echo ""
	echo -e "\t\tqdgentoo installer\n"
	echo -e "\trun on:" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)

	echo -e "\tuser: $USER"
	echo -e "\timezone: $timezone"
	echo -e "\tdisk: $disk"
	echo -e "\troot partition: $root_size"
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
	if [ -d /sys/firmware/efi ]; then
		parted $disk --script mklabel gpt
	else
		parted $disk --script mklabel msdos
	fi
	
	if [ $use_cfdisk = true ]; then
		cfdisk $disk
	else
		#EFI
		parted $disk --script mkpart primary fat32 1MiB $boot_size'MiB'
		parted $disk --script mkpart primary ext4 $boot_size'MiB' $root_size'GiB'
		parted $disk --script mkpart primary ext4 $root_size'GiB' 100%
	fi

	sleep 1
	mkfs.fat -F 32 $boot
	mkfs.ext4 $root
	mkfs.ext4 $home
 	mkdir /mnt/gentoo
	mount $root /mnt/gentoo
	makefs_2

}
################################	0.1
makefs_aes(){

	if [ -d /sys/firmware/efi ]; then
		parted $disk --script mklabel gpt
	else
		parted $disk --script mklabel msdos
	fi
	
	if $use_cfdisk; then
		cfdisk $disk
	else
		parted $disk --script mkpart primary fat32 1MiB $boot_size'MiB'
		parted $disk --script mkpart primary ext4 $boot_size'MiB' 100%
	fi
		
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
 	mkdir /mnt/gentoo
	mount /dev/mapper/vg0-root /mnt/gentoo
	makefs_2
}

makefs_2(){
	if [ -f stage3* ]; then
		cp stage3* /mnt/gentoo/stage3.tar.xz
	fi

	cd /mnt/gentoo

	if [ ! -f stage3* ]; then
		links https://www.gentoo.org/downloads/
	fi

	tar xpvf stage3*.tar.xz --xattrs-include='*.*' --numeric-owner
	if [ ! -z "$make_conf" ]; then
		wget $make_conf -O /mnt/gentoo/etc/portage/make.conf
	fi
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


	emerge --verbose --update --deep --newuse @world			


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

	if [ $simple_mode = false ]; then
		nano -w /etc/locale.gen
	fi

	locale-gen
	clear
	eselect locale set 6
	eselect locale list


	env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
	echo -e "\n### etc-update ###\n"
	etc-update

	if [ ! -z "$kernel" ]; then
		echo "$kernel" > /etc/portage/package.accept_keywords/kernel
	fi
	echo "sys-kernel/gentoo-sources experimental" >> /etc/portage/package.use/kernel
	emerge sys-kernel/gentoo-sources
	etc-update


	emerge sys-apps/pciutils
	etc-update


	mkdir /etc/portage/package.license
	echo "sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE" > /etc/portage/package.license/firmware
	emerge genkernel
	eselect kernel set 1
	etc-update
 
	if [ $simple_mode = true ]; then
 
		if [ $aes_yesno = true ]; then
  			genkernel --luks --lvm --no-zfs all
     	else
     		genkernel all
		fi
  
	else
 
		if [ $aes_yesno = true ]; then
  			genkernel --luks --lvm --no-zfs --menuconfig all
     	else
       		genkernel --menuconfig all
	  	fi
    
	fi


	if [ $aes_yesno = true ]; then
		echo "/dev/mapper/vg0-root		/		ext4		defaults	0 0" >> /etc/fstab
		echo "$boot		/boot		vfat		defaults        0 0" >> /etc/fstab
		echo "/dev/mapper/vg0-home		/home		ext4		defaults	0 0" >> /etc/fstab
	else
		echo "$root		/		ext4		defaults        0 0" >> /etc/fstab
		echo "$boot		/boot		vfat		defaults	0 0" >> /etc/fstab
		echo "$home		/home		ext4		defaults	0 0" >> /etc/fstab
	fi
	
	echo "tmpfs		/tmp		tmpfs		size=4G		0 0" >> /etc/fstab
	echo "tmpfs		/run		tmpfs		size=100M	0 0" >> /etc/fstab
	
	if [ $simple_mode = false ]; then
		nano -w /etc/fstab
	fi

	emerge app-admin/sysklogd net-misc/dhcpcd net-misc/chrony

	if [ $aes_yesno = true ]; then
		emerge sys-fs/lvm2
	fi
		
	passwd


	if [ -d /sys/firmware/efi ]; then
		echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	fi

	if [ $aes_yesno = true ]; then
		echo "sys-boot/boot:2 device-mapper" >> /etc/portage/package.use/sys-boot
	fi

	emerge --verbose sys-boot/grub:2

	if [ $aes_yesno = true ]; then
		echo 'GRUB_CMDLINE_LINUX="dolvm crypt_root='$root' root=/dev/mapper/vg0-root"' >> /etc/default/grub
	fi

	echo "$GRUB_CMDLINE_LINUX_DEFAULT" >> /etc/default/grub
	echo "#GRUB_GFXMODE=1920x1080x32" >> /etc/default/grub
	echo '#GRUB_BACKGROUND="/boot/grub/wow.png"' >> /etc/default/grub

	if [ $simple_mode = false ]; then
		nano /etc/default/grub
	fi

	if [ -d /sys/firmware/efi ]; then
		grub-install --target=x86_64-efi --efi-directory=/boot
	else
		grub-install $disk
	fi

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
	if $german; then
 		if [ -d /run/systemd/system ]; then
			localectl set-locale LC_MESSAGES=de_DE.utf8 LANG=de_DE.UTF-8 
			localectl set-keymap de
   		else
     		echo 'LANG="de_DE.UTF-8"' >> /etc/env.d/02locale
			echo 'LC_COLLATE="C.UTF-8"' >> /etc/env.d/02locale
   			echo 'keymap="de"' >> /etc/conf.d/keymaps
   			env-update && source /etc/profile
   		fi
	fi

	if [ -d /run/systemd/system ]; then
		hostnamectl hostname $hostname	
		systemctl enable --now dhcpcd
		#systemctl enable chronyd.service
		systemctl enable --now systemd-timesyncd.service
	else
		echo 'hostname="'$hostname'"' > /etc/conf.d/hostname
		rc-update add dhcpcd default
		rc-service dhcpcd start
		rc-update add chronyd default
	fi
}

################################  install base system
install_base_system(){
 	if $aes_yesno; then
		makefs_aes
	else
		makefs
	fi
	cp /root/qdgentoo.sh /mnt/gentoo/root/qdgentoo.sh
	chroot /mnt/gentoo /bin/bash -c "/root/qdgentoo.sh 1to9"
	umount_all
	poweroff
}
do_1_to_9(){
	do_in_chroot

   	echo "installation complete!"
   	echo "exit for reboot"
   	bash
}

################################	14
add_user(){
	emerge app-admin/sudo
	useradd -m -G users,wheel,audio -s /bin/bash $USER
	echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
 	echo "## user is allowed to execute halt and reboot" >> /etc/sudoers
 	echo "$USER ALL=NOPASSWD: /sbin/halt, /sbin/reboot, /sbin/poweroff" >> /etc/sudoers
	passwd $USER
#	passwd -l root
	cp qdgentoo.sh /home/$USER/
	usermod -a -G video $USER
	usermod -a -G input $USER
}
################################	15
install_wayland_sway(){
	cat <<EOF >> /etc/portage/package.use/wm
	gui-libs/wlroots X
	gui-wm/sway X wallpapers
	gui-apps/swaybg gdk-pixbuf
	media-libs/libepoxy X
	media-libs/libglvnd X
 	media-libs/mesa X
	EOF
  
	emerge --ask dev-libs/wayland gui-wm/sway dev-libs/light gui-apps/swaylock gui-apps/foot
	if [ ! -d /run/systemd/system ]; then
		rc-update add seatd default
	fi
}
################################	16
install_audio(){

	if [ whoami == root ]; then
		echo "media-video/pipewire pipewire-alsa sound-server" >> /etc/portage/package.use/pipewire
		emerge --ask alsa-utils pipewire
		sudo -u $USER /bin/bash -c "qdgentoo.sh install_audio"
	else
		if [ -d /run/systemd/system ]; then
			systemctl --user enable --now pipewire.socket
			systemctl --user enable --now pipewire.service
			systemctl --user enable --now wireplumber.service
			systemctl --user mask pulseaudio.socket pulseaudio.service
			systemctl --user enable --now pipewire-pulse.service
		else
			rc-update add alsasound boot
		fi
	fi
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

################################	99
update_installer(){
	mv qdgentoo.sh qdgentoo.old
	wget https://raw.githubusercontent.com/cs97/qdgentoo/simplified-2.x/qdgentoo.sh
	chmod +x qdgentoo.sh
	chmod -x qdgentoo.old
}

################################	switch
if [ "$EUID" -ne 0 ]; then
	echo "Please run as root" #&& exit
fi


case $1 in
	"install") install_base_system;;	#base system install
	"first_boot") first_boot;;
	"add_user") add_user;;
	"install_sway") install_wayland_sway;;
	"install_wifi") install_wifi;;
	"install_audio") install_audio;;

	"1to9") do_1_to_9;;
	"update") update_installer;;
	*) simple_banner;;
esac


exit
