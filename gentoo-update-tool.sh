#! /bin/bash

#Gentoo-Update-Tool
#easy to use system updater

banner(){
	echo ""
	echo -e "Gentoo-Update-Tool\n"
	echo -e "usage: $0 [OPTION]\n"
	echo -e "\t--update\t\temerge --sync;\n\t\t\t\temerge --ask --verbose --update --newuse --deep @world\n"
	echo -e "\t--kernel-list\t\teselect kernel list\n"
	echo -e "\t--kernel-set <?>\teselect kernel set x\n"
	echo -e "\t--genkernel\t\tgenkernel --menuconfig all\n"
	echo -e "\t--grub-update\t\tgrub-mkconfig -o /boot/grub/grub.cfg\n"
}

case $1 in
	"--update")
			emerge --sync
			emerge --ask --verbose --update --newuse --deep @world;;

	"--kernel-list") eselect kernel list;;

	"--kernel-set") eselect kernel set $2;;

	"--genkernel") genkernel --menuconfig all;;

	"--grub-update") grub-mkconfig -o /boot/grub/grub.cfg;;


	*) banner;;
esac
