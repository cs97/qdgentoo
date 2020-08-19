
kernel update

nanp /etc/portage/package.accept_keywords
```    
=sys-kernel/gentoo-sources-5.8.1 ~amd64
```
install sources:
```
emerge --ask sys-kernel/gentoo-sources
```

eselect kernel list
```
genkernel --menuconfig all
OR
genkernel --luks --lvm --no-zfs --menuconfig all
```

grub
```
grub-mkconfig -o /boot/grub/grub.cfg
```

nfs
> emerge --ask net-fs/nfs-utils

> x.x.x.x:/data   /home/user/data   nfs	  rw,noauto,user 0 0          #/etc/fstab

