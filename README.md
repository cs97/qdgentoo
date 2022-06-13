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





