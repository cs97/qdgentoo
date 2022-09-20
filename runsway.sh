#!/bin/sh
# start sway on OpenRC and Systemd

# quick and dirty fix for OpenRC

#[ -d /run/systemd/system ] || 
    

[ -z ${XDG_RUNTIME_DIR} ] && {
     export XDG_RUNTIME_DIR=/tmp/${UID}-runtime-dir
    [ -d ${XDG_RUNTIME_DIR} ] && {
        mkdir ${XDG_RUNTIME_DIR}
        chmod 0700 ${XDG_RUNTIME_DIR}
    }
}


case $1 in
	"--igpu") [ -d /dev/dri/card1 ] && WLR_DRM_DEVICES="/dev/dri/card1" sway --unsupported-gpu || WLR_DRM_DEVICES="/dev/dri/card0" sway --unsupported-gpu;;
	"--dgpu") sway --unsupported-gpu;;
	*) echo "usage: $0 [--igpu|--dgpu]";;
esac
