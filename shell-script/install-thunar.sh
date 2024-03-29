#! /bin/bash

cat <<EOF >> /etc/portage/package.use/thunar
xfce-base/thunar udisks
media-libs/libopenraw gtk
xfce-extra/tumbler ffmpeg jpeg raw pdf
app-text/poppler cairo
gnome-base/gvfs udisks
sys-apps/systemd policykit
dev-libs/libdbusmenu gtk3
x11-libs/gtk+ X
app-crypt/gcr gtk
EOF

cat <<EOF >> /etc/portage/package.use/arc-dark
x11-themes/arc-theme xfce -gtk2
x11-libs/cairo X
EOF

sudo emerge --ask thunar xfce4-settings x11-themes/arc-theme app-arch/file-roller

#echo "-> xfce4-appearance-settings -> arc-dark"
echo "gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'"
