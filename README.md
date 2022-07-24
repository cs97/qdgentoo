# Gentoo Linux Installer

### Install
```
./qdgentoo.sh
```
```
./qdgentoo.sh 0
...
./qdgentoo.sh 10
```

### wlan

```
nmtui
```

### kernel update

/etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-5.18.3 ~amd64
```
install sources:
```
emerge --ask sys-kernel/gentoo-sources
```
select the new kernel:
```
eselect kernel list
eselect kernel set <x>
```

genkernel:
```
genkernel --menuconfig all
OR
genkernel --luks --lvm --no-zfs --menuconfig all
```

grub
```
grub-mkconfig -o /boot/grub/grub.cfg
```

### nfs mount
```
emerge --ask net-fs/nfs-utils
```
```sh
mkdir /home/user/data
```
/etc/fstab
```
x.x.x.x:/data   /home/user/data   nfs	  rw,noauto,user 0 0
```
### openvpn
```
cp myvpn.ovpn /etc/openvpn/myvpn.conf
sudo ln -s /etc/init.d/openvpn /etc/init.d/openvpn.myvpn
/etc/init.d/openvpn.myvpn start
sudo rc-update add openvpn.myvpn default
```
### thunar
/etc/portage/package.use/thunar
```
xfce-base/thunar udisks
media-libs/libopenraw gtk
xfce-extra/tumbler ffmpeg jpeg raw pdf
app-text/poppler cairo
```
/etc/portage/package.use/arc-dark
```
x11-themes/arc-theme xfce
```
```
sudo emerge --ask x11-themes/arc-theme
sudo emerge --ask thunar
sudo emerge --ask xfce-extra/tumbler
sudo emerge --ask xfce4-settings
```
```
-> xfce4-appearance-settings -> arc-dark
```

### video Player
/etc/portage/package.use/mpv
```
media-video/mpv X wayland
```
```
sudo emerge --ask mpv
```

### discord
nano /etc/portage/package.license/discord
```
net-im/discord-bin all-rights-reserved
```
/etc/portage/package.accept_keywords/discord
```
net-im/discord-bin ~amd64
```
/etc/portage/package.use/discord
```
app-text/ghostscript-gpl cups
```
```
emerge --ask net-im/discord-bin
```
### stuff...
```
app-crypt/gnupg
app-misc/neofetch
sys-apps/lm-sensors
sys-apps/smartmontools
sys-apps/hdparm
file-roller
sys-apps/bat
xfce-base/thunar
app-arch/file-roller
```





