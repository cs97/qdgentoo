#!/bin/sh
# start sway on OpenRC and Systemd

# quick and dirty fix for OpenRC
[ -d /run/systemd/system ] || udevadm trigger

case $1 in
	"--igpu") [ -d /dev/dri/card1 ] && WLR_DRM_DEVICES="/dev/dri/card1" sway --unsupported-gpu || WLR_DRM_DEVICES="/dev/dri/card0" sway --unsupported-gpu;;
	"--dgpu") sway --unsupported-gpu;;
	*) echo "usage: $0 [--igpu|--dgpu]";;
esac
