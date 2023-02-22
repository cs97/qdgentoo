# Gentoo Linux Installer

### Install
```
./qdgentoo.sh install
```
### add user
```
./qdgentoo.sh add_user
```
### install sway
```
./qdgentoo.sh install_sway
```

### wlan

```
nmtui
```
### update
```  
sudo emerge --sync
sudo emerge --ask --verbose --update --newuse --deep @world
```    

### kernel update

/etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-6.1.3 ~amd64
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
sudo genkernel --menuconfig all
OR
sudo genkernel --menuconfig --kernel-config=/etc/kernels/kernel-config-6.1.X-gentoo-x86_64 all
OR
sudo genkernel --luks --lvm --no-zfs --menuconfig all
```

grub
```
sudo grub-mkconfig -o /boot/grub/grub.cfg
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
gnome-base/gvfs udisks
sys-apps/systemd policykit
dev-libs/libdbusmenu gtk3
x11-libs/gtk+ X
app-crypt/gcr gtk
```
/etc/portage/package.use/arc-dark
```
x11-themes/arc-theme xfce
x11-libs/cairo X
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


### stuff...
```
app-crypt/gnupg
sys-apps/smartmontools
sys-apps/hdparm
sys-apps/bat
```





