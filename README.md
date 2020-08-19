

### make.conf
/etc/portage/make.conf #my e495
```
COMMON_FLAGS="-march=native -O2 -pipe"
MAKEOPTS="-j8"
USE="elogind alsa pulseaudio"
CPU_FLAGS_X86="aes avx avx2 f16c fma3 mmx mmxext pclmul popcnt sha sse sse2 sse3 sse4_1 sse4_2 sse4a ssse3"

```


### kernel update

nanp /etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-5.8.1 ~amd64
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

### no cpu boot

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

nfs mount
```
emerge --ask net-fs/nfs-utils
mkdir /home/user/data
x.x.x.x:/data   /home/user/data   nfs	  rw,noauto,user 0 0          #/etc/fstab
```
