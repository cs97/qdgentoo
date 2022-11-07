#! /bin/bash

cat <<EOF >> /etc/portage/package.use/vbox
app-emulation/virtualbox X egl
dev-qt/qtgui X egl
x11-libs/libxkbcommon X
EOF

emerge --ask --verbose app-emulation/virtualbox
