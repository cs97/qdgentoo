#! /bin/bash

cat <<EOF >> /etc/portage/package.use/qemu
app-emulation/qemu gtk sdl opengl virgl spice
app-emulation/qemu  qemu_softmmu_targets_x86_64
app-emulation/qemu qemu_user_targets_x86_64
dev-libs/libclc spirv
EOF

emerge --ask --verbose app-emulation/qemu sys-firmware/edk2-ovmf-bin
gpasswd -a $USER kvm
