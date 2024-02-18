# Gentoo Linux Installer

### 1. Install
```
./qdgentoo.sh install
```
### 2. first_boot
```
./qdgentoo.sh first_boot
```
### 3. add user
```
./qdgentoo.sh add_user
```
### 4. install sway
```
./qdgentoo.sh install_sway
```

### update
```  
sudo emerge --sync
sudo emerge --ask --verbose --update --newuse --deep @world
```    

### kernel update

/etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-6.5.3 ~amd64
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

### kernel removal
```
sudo emerge --ask --depclean gentoo-sources
rm -r /usr/src/linux-5.*
```
### Ooen-rc Network
/etc/conf.d/net.your-network-card
```
config_your-network-card="dhcp"
```
```
ln -s /etc/init.d/net.{lo,your-network-card}
```
```
rc-update add net.your-network-card default
```

### wlan

```
nmtui
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





