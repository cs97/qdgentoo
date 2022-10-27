#! /bin/bash

cat <<EOF >> /etc/portage/package.use/wm
gui-libs/wlroots X
gui-wm/sway X
EOF

cat <<EOF >> /etc/portage/package.accept_keywords/steam
*/*::steam-overlay
EOF

emerge --ask --noreplace app-eselect/eselect-repository dev-vcs/git
eselect repository enable steam-overlay
emaint sync -r steam-overlay

cat <<EOF >> /etc/portage/package.license/steam
games-util/steam-launcher ValveSteamLicense
EOF

cat <<EOF >> /etc/portage/package.use/steam
>=x11-libs/libX11-1.8.1 abi_x86_32
>=x11-libs/libXau-1.0.10 abi_x86_32
>=x11-libs/libxcb-1.15-r1 abi_x86_32
>=x11-libs/libXdmcp-1.1.3-r1 abi_x86_32
>=dev-libs/libbsd-0.11.7 abi_x86_32
>=app-crypt/libmd-1.0.4 abi_x86_32
>=virtual/opengl-7.0-r2 abi_x86_32
>=x11-libs/gtk+-3.24.34-r1 X
>=media-libs/libepoxy-1.5.10-r1 X
>=x11-libs/cairo-1.16.0-r6 X
>=media-libs/mesa-22.2.2 X abi_x86_32
>=media-libs/libglvnd-1.5.0 X

>=dev-libs/expat-2.5.0 abi_x86_32
>=media-libs/libglvnd-1.5.0 abi_x86_32
>=sys-libs/zlib-1.2.13-r1 abi_x86_32
>=dev-libs/wayland-1.21.0 abi_x86_32
>=x11-libs/libdrm-2.4.113 abi_x86_32
>=x11-libs/libxshmfence-1.3.1 abi_x86_32
>=x11-libs/libXext-1.3.4 abi_x86_32
>=x11-libs/libXxf86vm-1.1.5 abi_x86_32
>=x11-libs/libXfixes-6.0.0 abi_x86_32
>=app-arch/zstd-1.5.2-r3 abi_x86_32
>=sys-devel/llvm-15.0.3 abi_x86_32
>=x11-libs/libXrandr-1.5.2 abi_x86_32
>=x11-libs/libXrender-0.9.11 abi_x86_32
>=dev-libs/libffi-3.4.4 abi_x86_32
>=sys-libs/ncurses-6.3_p20220924 abi_x86_32
>=virtual/libelf-3-r1 abi_x86_32
>=dev-libs/elfutils-0.187-r2 abi_x86_32
>=app-arch/bzip2-1.0.8-r3 abi_x86_32
EOF

emerge --ask --verbose --update --changed-use --deep @world

emerge --ask games-util/steam-launcher






