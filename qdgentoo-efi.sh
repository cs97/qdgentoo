#! /bin/bash

USER='user'

aes_yesno=false

kernel='=sys-kernel/gentoo-sources-5.10.27 ~amd64'
		# no aes	aes
part1="1GiB"	# (boot)	(boot)
part2="30GiB"	# (root)	(lvm)
part3="100%"	# (home)

#echo 0 > /sys/devices/system/cpu/cpufreq/boost

#disk='/dev/sda'
disk='/dev/nvme0n1'
boot=$disk'1'
root=$disk'2'
home=$disk'3'

banner(){
	clear
	echo "#######################################"
	echo "#                                    #"
	echo "#             qdgentoo-efi           #"
	echo "#                                    #"
	echo "######################################"
	echo "run on" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
	echo "disk: $disk"
	echo "aes: $aes_yesno"
	echo "install: $kernel"
	echo "######################################"
	echo "#                                    #"
	echo "#  0   makefs                        #"
	echo "#  1   do in chroot                  #"
	echo "#  2   @world                        #"
	echo "#  3   locale                        #"
	echo "#  4   env-update                    #"
	echo "#  5   gentoo-sources                #"
	echo "#  6   pciutils                      #"
	echo "#  7   genkernel                     #"
	echo "#  8   fstab & Stuff                 #"
	echo "#  9   grub                          #"
	echo "#  10  reboot                        #"
	echo "#                                    #"
	echo "#  11  wget qdgentoo-i3.sh           #"
	echo "#  99. update                        #"
	echo "######################################"
	echo ""
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
		parted $disk --script mkpart primary fat32 1MiB $part1
		parted $disk --script mkpart primary ext4 $part1 $part2
		parted $disk --script mkpart primary ext4 $part2 $part3
	} || {
		parted $disk --script mklabel msdos
		parted $disk --script mkpart primary ext4 1MiB $part1
		parted $disk --script mkpart primary ext4 $part1 $part2
		parted $disk --script mkpart primary ext4 $part2 $part3
	}
	
	#cfdisk $disk
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
		parted /dev/$disk --script mkpart primary ext4 1MiB $part1
		parted /dev/$disk --script mkpart primary ext4 $part1 $part2
	} || {
		parted /dev/$disk --script mklabel msdos
		parted /dev/$disk --script mkpart primary ext4 1MiB $part1
		parted /dev/$disk --script mkpart primary ext4 $part1 $part2
	}
	
	#cfdisk $disk
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
	#cp /root/stage3.tar.xz /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo
	links https://www.gentoo.org/downloads/
	tar xpvf stage3.tar.xz --xattrs-include='*.*' --numeric-owner
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
	cp ~/qdgentoo-efi.sh /mnt/gentoo/qdgentoo-efi.sh
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
	nano -w /etc/locale.gen
	locale-gen
	clear
	eselect locale set 6
	eselect locale list
	}
################################	4
env_update(){
	env-update && source /etc/profile && export PS1="(chroot) ${PS1}"
	etc-update
}
################################	5
gentoo_sources(){
	echo "$kernel" > /etc/portage/package.accept_keywords
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
	emerge --ask genkernel
	etc-update
	[ $aes_yesno = true ] && genkernel --luks --lvm --no-zfs --menuconfig all || genkernel --menuconfig all
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
	
	echo 'hostname="gentoo-pc"' >> /etc/conf.d/hostname
	emerge --ask --noreplace net-misc/netifrc
	passwd
	emerge --ask app-admin/sysklogd
	#rc-update add sysklogd default
	emerge --ask net-misc/dhcpcd
}

################################	9.2
install_grub_efi(){
	[ -d /sys/firmware/efi ] && echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	emerge --ask --verbose sys-boot/grub:2
	[ -d /sys/firmware/efi ] && grub-install --target=x86_64-efi --efi-directory=/boot || grub-install $disk
	grub-mkconfig -o /boot/grub/grub.cfg
}
################################	9.3
install_grub_aes_efi(){
	[ -d /sys/firmware/efi ] && echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
	echo "sys-boot/boot:2 device-mapper" >> /etc/portage/package.use/sys-boot
	emerge --ask --verbose sys-boot/grub:2
	echo 'GRUB_CMDLINE_LINUX="dolvm crypt_root='$root' root=/dev/mapper/vg0-root"' >> /etc/default/grub
	nano /etc/default/grub
	[ -d /sys/firmware/efi ] && grub-install --target=x86_64-efi --efi-directory=/boot || grub-install $disk
	grub-mkconfig -o /boot/grub/grub.cfg
}
################################	10
reboot_now(){
	cd
	umount -l /mnt/gentoo/dev{/shm,/pts,}
	umount -R /mnt/gentoo
	reboot
}


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
	"9") [ $aes_yesno = true ] && install_grub_aes_efi || install_grub_efi;;
	"10") reboot_now;;
	"11") 
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/qdgentoo-i3.sh
		chmod +x qdgentoo-i3.sh;;
	
	"99")
		mv qdgentoo-efi.sh qdgentoo-efi.old
		wget https://raw.githubusercontent.com/leftside97/qdgentoo/master/qdgentoo-efi.sh
		chmod +x qdgentoo-efi.sh
		chmod -x qdgentoo-efi.old;;

	*) banner;;
esac
exit

