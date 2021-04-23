

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


### make.conf
/etc/portage/make.conf #my e495
```
COMMON_FLAGS="-march=native -O2 -pipe"
MAKEOPTS="-j8"
USE="experimental elogind alsa pulseaudio"
CPU_FLAGS_X86="aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sha sse sse2 sse3 sse4_1 sse4_2 sse4a ssse3"

```


### kernel update

/etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-5.11.16 ~amd64
```
install sources:
```
emerge --ask sys-kernel/gentoo-sources
```
select the new kernel:
```
eselect kernel list
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

```
#!/bin/bashe
echo 0 > /sys/devices/system/cpu/cpufreq/boost
```
```
chmod +x /etc/local.d/noboost.start
rc-update add local default```
```
### eco 
```
emerge sys-power/cpupower
```
/etc/local.d/powersave.start

```
#!/bin/bashe
cpupower frequency-set -g powersave
```
```
chmod +x /etc/local.d/powersave.start
rc-update add local default```
```
### virtualbox
/etc/portage/package.accept_keywords
```
=app-emulation/virtualbox-6.1.16 ~amd64
=app-emulation/virtualbox-modules-6.1.16 ~amd64
```
```
emerge --ask app-emulation/virtualbox
modprobe vboxdrv
```

### nfs mount
```
emerge --ask net-fs/nfs-utils
```
```
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





