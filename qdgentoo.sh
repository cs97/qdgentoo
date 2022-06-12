#! /bin/bash

USER='user'

aes_yesno=false
load_makeconf=true
use_cfdisk=true

kernel='=sys-kernel/gentoo-sources-5.18.3 ~amd64'
GRUB_CMDLINE_LINUX_DEFAULT='GRUB_CMDLINE_LINUX_DEFAULT="modprobe.blacklist=nouveau quiet splash"'

part1="1MiB 1024MiB"
part2="1025MiB 32768MiB"
part3="32769MiB 100%"
partlvm="1025MiB 100%"

#echo 0 > /sys/devices/system/cpu/cpufreq/boost

disk='/dev/nvme0n1'
boot=$disk'p1'
root=$disk'p2'
home=$disk'p3'

#disk='/dev/sda'
#boot=$disk'1'
#root=$disk'2'
#home=$disk'3'


banner(){
	clear
	echo
	echo ""
	echo -e "\t\tqdgentoo\n"
	echo -e "\trun on" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
	echo -e "\tuser: $USER"
	echo -e "\tdisk: $disk"
	echo -e "\taes: $aes_yesno"
	echo -e "\tload_makeconf: $load_makeconf"
	echo -e "\tuse cfdisk: $use_cfdisk\n"
#	echo -e "\tinstall: $kernel\n"
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
	echo -e "\t11.add user"	
	echo -e "\t12.wayland"
	echo -e "\t13.sway"
	echo -e "\t14.install_audio"
	echo -e "\t15.sway_config"
	echo -e "\t16.mount_again"
	echo -e "\t17.install_wifi"
	echo -e "\t18.install_amdgpu"
	echo -e "\t19.install_nvidia"
	echo -e "\t20.install_thunar"
	echo -e "\t21.install_ecomode\n"
	
	echo -e "\t99. update\n"

}
################################	0
makefs(){
	#parted $disk --script mklabel gpt
	#parted $disk --script mkpart primary ext4 32MiB 100MiB
	#parted $disk --script mkpart primary fat32 100MiB 1GiB
	#parted $disk --script mkpart primary ext4 1GiB 30GiB
	#parted $disk --script mkpart primary ext4 30GiB 100%
	
	[ -d /sys/firmware/efi ] && {
		parted $disk --script mklabel gpt
		#parted $disk --script mkpart primary fat32 1MiB $part1
		#parted $disk --script mkpart primary ext4 $part1 $part2
		#parted $disk --script mkpart primary ext4 $part2 $part3
	} || {
		parted $disk --script mklabel msdos
		#parted $disk --script mkpart primary ext4 1MiB $part1
		#parted $disk --script mkpart primary ext4 $part1 $part2
		#parted $disk --script mkpart primary ext4 $part2 $part3
	}
	
	[ $use_cfdisk = true ] && {
		cfdisk $disk
	} || {
		parted $disk --script mkpart primary fat32 $part1
		parted $disk --script mkpart primary ext4 $part2
		parted $disk --script mkpart primary ext4 $part3	
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
		#parted /dev/$disk --script mkpart primary ext4 $part1
		#parted /dev/$disk --script mkpart primary ext4 $partlvm
	} || {
		parted /dev/$disk --script mklabel msdos
		#parted /dev/$disk --script mkpart primary ext4 $part1
		#parted /dev/$disk --script mkpart primary ext4 $partlvm
	}
	
	[ $use_cfdisk = true ] && {
		cfdisk $disk
	} || {
		parted /dev/$disk --script mkpart primary ext4 $part1
		parted /dev/$disk --script mkpart primary ext4 $partlvm
	}
		
	sleep 1
	mkfs.fat -F 32 $boot
	modprobe dm-crypt
	cryptsetup luksFormat --type luks1 $root
	cryptsetup luksOpen $root lvm
	lvm pvcreate /dev/mapper/lvm
	vgcreate vg0 /dev/mapper/lvm
	lvcreate -L 30G -n root vg0
	lvcreate -l 100%FREE -n home vg0
	mkfs.ext4 /dev/mapper/vg0-root
	mkfs.ext4 /dev/mapper/vg0-home
	mount /dev/mapper/vg0-root /mnt/gentoo
	makefs_2
}

makefs_2(){
	#cp stage3* /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo
	links https://www.gentoo.org/downloads/
	tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner
	[ $load_makeconf = true ] && wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/conf/make.conf -O /mnt/gentoo/etc/portage/make.conf
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
	echo "en_US ISO-8859-1" >> /etc/locale.gen
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	#echo "de_DE ISO-8859-1" >> /etc/locale.gen
	#echo "de_DE@euro ISO-8859-15" >> /etc/locale.gen
	#echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
	nano -w /etc/locale.gen
	locale-gen
	clear
	eselect locale set 6
	eselect locale list
	#localectl set-keymap de
	}
################################	4
env_update(){
	env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
	etc-update
}
################################	5
gentoo_sources(){
	echo "$kernel" > /etc/portage/package.accept_keywords/kernel
	echo "sys-kernel/gentoo-sources experimental" >> /etc/portage/package.use/kernel
	emerge --ask sys-kernel/gentoo-sources
	etc-update
}
################################	6
pci_utils(){
	emerge --ask sys-apps/pciutils
	etc-update
}
################################	7
gentoo_genkernel(){
	mkdir /etc/portage/package.license
	echo "sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE" > /etc/portage/package.license/firmware
	emerge --ask genkernel
	eselect kernel set 1
	etc-update
	[ $aes_yesno = true ] && genkernel --luks --lvm --no-zfs --menuconfig all || genkernel --menuconfig all
}
################################	8
fstab_stuff(){
	etc-update
	emerge --ask sys-kernel/linux-firmware
	etc-update
	
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
	
	nano -w /etc/fstab
	#echo 'hostname="gentoo-pc"' >> /etc/conf.d/hostname
	hostnamectl hostname gentoo-pc
	#emerge --ask --noreplace net-misc/netifrc
	passwd
	emerge --ask app-admin/sysklogd
	#rc-update add sysklogd default
	emerge --ask net-misc/dhcpcd
}
################################	9.2
install_grub_efi(){
	[ -d /sys/firmware/efi ] && echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	[ $aes_yesno = true ] && echo "sys-boot/boot:2 device-mapper" >> /etc/portage/package.use/sys-boot
	emerge --ask --verbose sys-boot/grub:2
	[ $aes_yesno = true ] && echo 'GRUB_CMDLINE_LINUX="dolvm crypt_root='$root' root=/dev/mapper/vg0-root"' >> /etc/default/grub
	echo "$GRUB_CMDLINE_LINUX_DEFAULT" >> /etc/default/grub
	echo "#GRUB_GFXMODE=1920x1080x32" >> /etc/default/grub
	nano /etc/default/grub
	[ -d /sys/firmware/efi ] && grub-install --target=x86_64-efi --efi-directory=/boot || grub-install $disk

	grub-mkconfig -o /boot/grub/grub.cfg
}
################################	10
umount_all(){
	cd
	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo
	#reboot
}
################################	11
add_user(){
	emerge --ask app-admin/sudo
	useradd -m -G users,wheel,audio -s /bin/bash $USER
#	echo "exec i3" >> /home/$USER/.xinitrc
	echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
	passwd $USER
#	passwd -l root
	cp qdgentoo.sh /home/$USER/
	#emerge xrandr
	#echo "user:" $USER
	usermod -a -G video $USER
	usermod -a -G input $USER
}
################################	12
install_wayland(){
	emerge --ask dev-libs/wayland
}
################################	13
install_sway(){
	echo "gui-wm/sway wallpapers" >> /etc/portage/package.use/wm
	emerge --ask gui-wm/sway
	emerge --ask dev-libs/light
	emerge --ask x11-terms/alacritty
}
################################	14
install_audio(){
	echo "media-video/pipewire pipewire-alsa" >> /etc/portage/package.use/pipewire
	emerge --ask alsa-utils pipewire
}
################################	15
sway_config(){
	mv ~/.config/sway/config ~/.config/sway/config.old
	wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/conf/config
	mv ~/config ~/.config/sway/config
	wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/conf/status.sh
	chmod +x status.sh
	mv ~/status.sh ~/.config/sway/status.sh
	chmod +x ~/.config/sway/status.sh
	echo '#!/bin/sh' > ~/runwm.sh
	echo '"WLR_DRM_DEVICES="/dev/dri/card1" sway --unsupported-gpu' >> ~/runwm.sh
	chmod +x runwm.sh
}
################################	16
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
################################	17
install_wifi(){
	emerge --ask networkmanager
	emerge --ask nm-applet
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
	#echo ">=x11-drivers/nvidia-drivers-515.48.07" >> /etc/portage/package.accept_keywords/nvidia
	echo "=x11-drivers/nvidia-drivers-510.73.05-r1" >> /etc/portage/package.accept_keywords/nvidia
	echo "x11-drivers/nvidia-drivers -tools" >> /etc/portage/package.use/nvidia
	emerge --ask x11-drivers/nvidia-drivers
	#emerge --ask --verbose --update --newuse --deep @world
}
################################	20
install_thunar(){
	echo "xfce-base/thunar udisks" >> /etc/portage/package.accept_keywords/wm
	#emerge --ask --verbose --update --newuse --deep @world
	emerge --ask xfce-base/thunar
}
################################	21
install_ecomode(){
	emerge --ask cpupower
	touch /etc/systemd/system/lowturbo.service
	echo "[Unit]" >> /etc/systemd/system/lowturbo.service
	echo "Description=LowTurbo" >> /etc/systemd/system/lowturbo.service
	echo "" >> /etc/systemd/system/lowturbo.service
	echo "[Service]" >> /etc/systemd/system/lowturbo.service
	echo "Type=oneshot" >> /etc/systemd/system/lowturbo.service
	echo "" >> /etc/systemd/system/lowturbo.service
	echo "ExecStart=/bin/sh -c "/usr/bin/cpupower frequency-set --max 3300MHz"" >> /etc/systemd/system/lowturbo.service
	echo "" >> /etc/systemd/system/lowturbo.service
	echo "ExecStop=/bin/sh -c "/usr/bin/cpupower frequency-set --max 5000MHz"" >> /etc/systemd/system/lowturbo.service
	echo "" >> /etc/systemd/system/lowturbo.service
	echo "RemainAfterExit=yes" >> /etc/systemd/system/lowturbo.service
	echo "" >> /etc/systemd/system/lowturbo.service
	echo "[Install]" >> /etc/systemd/system/lowturbo.service
	echo "WantedBy=multi-user.target" >> /etc/systemd/system/lowturbo.service
	
	systemctl start lowturbo
	systemctl enable lowturbo
}
################################	switch
[ "$EUID" -ne 0 ] && echo "Please run as root" #&& exit

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
	"11") add_user;;
	"12") install_wayland;;
	"13") install_sway;;
	"14") install_audio;;
	"15") sway_config;;
	"16") mount_again;;
	"17") install_wifi;;
	"18") install_amdgpu;;
	"19") install_nvidia;;
	"20") install_thunar;;
	"21") install_ecomode;;
	"99")
		mv qdgentoo.sh qdgentoo.old
		wget https://raw.githubusercontent.com/cs97/qdgentoo/master/qdgentoo.sh
		chmod +x qdgentoo.sh
		chmod -x qdgentoo.old;;
	"-m")
		banner
		echo -en "\tEnter option: "
		read option
		$0 $option;;
		
	*) banner;;
esac
exit
