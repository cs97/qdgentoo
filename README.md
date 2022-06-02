### wlan

```
emerge --ask net-wireless/iw net-wireless/wpa_supplicant
```
```
wpa_passphrase <WLAN> >> /etc/wpa_supplicant/wpa_supplicant.conf
```
```
/etc/init.d/wpa_supplicant start
rc-update add wpa_supplicant default
```

### kernel update

/etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-5.17.1 ~amd64
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

### no cpu boost

/etc/local.d/noboost.start

```sh
#!/bin/bash
echo 0 > /sys/devices/system/cpu/cpufreq/boost
```
```
chmod +x /etc/local.d/noboost.start
rc-update add local default
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
app-misc/screenfetch
sys-apps/lm-sensors
sys-apps/smartmontools
sys-apps/hdparm
x11-apps/xbacklight
app-misc/mc
cdrtools
thunar
file-roller
dev-util/android-tools

emerge --ask elogind
rc-update add elogind boot
```





