#! /bin/bash

USER='user'

aes_yesno=true

kernel='=sys-kernel/gentoo-sources-5.7.10 ~amd64'



disk='/dev/nvme0n1'		
uefi='/dev/nvme0n1p1'	# 2M		
boot='/dev/nvme0n1p2'	# 1G		(fat32 UEFI)	(fat32 UEFI)
root='/dev/nvme0n1p3'	# 30G		(root)		(lvm)
home='/dev/nvme0n1p4'	# 100%FREE	(home)		(x)

banner(){
	clear
	echo "###########################################################################"
	echo "#                                                                         #"
	echo "#                              qdgentoo-efi                               #"
	echo "#                                                                         #"
	echo "###########################################################################"
	echo "run on" $([ -d /sys/firmware/efi ] && echo UEFI || echo BIOS)
	echo "$kernel"
	echo "###########################################################################"
	echo "#                                    #                                    #"
	echo "#  0   makefs                        #                                    #"
	echo "#  1   do in chroot                  #                                    #"
	echo "#  2   @world                        #                                    #"
	echo "#  3   locale                        #                                    #"
	echo "#  4   env-update                    #                                    #"
	echo "#  5   gentoo-sources                #                                    #"
	echo "#  6   pciutils                      #                                    #"
	echo "#  7   genkernel                     #                                    #"
	echo "#  8   fstab & Stuff                 #                                    #"
	echo "#  9   grub                          #                                    #"
	echo "#  10  reboot                        #                                    #"
	echo "#                                    #                                    #"
	echo "#                                    #                                    #"
	echo "#                                    #                                    #"
	echo "#                                    #                                    #"
	echo "#                                    #                                    #"
	echo "#                                    #                                    #"
	echo "#  13  genkernel_update              #                                    #"
	echo "#  14  genkernel_aes_update          #                                    #"
	echo "#  15  nano make.conf                #                                    #"
	echo "#  99. update                        #                                    #"
	echo "###########################################################################"
	echo ""
}
################################	0
makefs(){
	cfdisk $disk
	sleep 1
	mkfs.fat -F 32 $boot
	mkfs.ext4 $root
	mkfs.ext4 $home
	mount $root /mnt/gentoo
	makefs_2

}
################################	0.1
makefs_aes(){
	cfdisk $disk
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
	cp /root/stage3.tar.xz /mnt/gentoo/stage3.tar.xz
	cd /mnt/gentoo
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
	passwd
	emerge --ask app-admin/sysklogd
	rc-update add sysklogd default
	emerge --ask net-misc/dhcpcd
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
	echo "grub-mkconfig -o /boot/grub/grub.cfg"
}
################################	14
genkernel_aes_update(){
	emerge --sync
	echo "$kernel" >> /etc/portage/package.accept_keywords
	emerge --ask sys-kernel/gentoo-sources
	eselect kernel list
	echo "eselect kernel set X"
	echo "genkernel --luks --lvm --no-zfs --menuconfig all"
	echo "grub-mkconfig -o /boot/grub/grub.cfg"
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
		if [ $aes_yesno = false ]; then
			install_grub_efi
		else
			install_grub_aes_efi
		fi;;
	"10") reboot_now;;
	"13") genkernel_update ;;
	"14") genkernel_aes_update ;;
	"15") nano -w /etc/portage/make.conf ;;

	"99")
		mv qdgentoo-efi.sh qdgentoo-efi.old
		wget https://raw.githubusercontent.com/l3f7s1d3/qdgentoo/master/qdgentoo-efi.sh
		chmod +x qdgentoo-efi.sh;;

	*) banner;;
esac
exit

