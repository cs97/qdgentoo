#! /bin/bash

echo ">=app-emulation/virtualbox X egl" > /etc/portage/package.use/vbox

echo ">=dev-qt/qtgui X egl" >> /etc/portage/package.use/vbox

emerge --ask --verbose app-emulation/virtualbox
