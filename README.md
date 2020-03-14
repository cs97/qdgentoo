### quick &amp; dirty gentoo

> dd if=live.iso of=/dev/sdX

> cfdisk /dev/sdX     # + sdX3

> mkfs.ext4 /dev/sdX3

copy qdgentoo.sh to sdX3

copy stage3.tar.xz to sdX3

chmod +x qdgentoo.sh

boot from sdX

> mount /dev/sdX3 /root

> cd /root

> ./qdgentoo.sh


