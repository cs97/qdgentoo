#!/bin/sh

[ -f /usr/bin/cpupower ] || {
	echo "install cpupower"
	exit
}

performance(){
	echo 1 > /sys/devices/system/cpu/cpufreq/boost
	cpupower frequency-set --max 3300MHz
	cpupower frequency-set --min 2000MHz
	cpupower frequency-set --governor schedutil
	[ -f /opt/bin/nvidia-smi ] && {
		nvidia-smi -lgc 210,1200
		nvidia-smi -lmc 400,5800
	}
}

balanced(){
	echo 0 > /sys/devices/system/cpu/cpufreq/boost
	cpupower frequency-set --max 3300MHz
	cpupower frequency-set --min 1000MHz
	cpupower frequency-set --governor schedutil
	[ -f /opt/bin/nvidia-smi ] && {
		nvidia-smi -lgc 210,1000
		nvidia-smi -lmc 400,5800
	}
}

powersave(){
	echo 0 > /sys/devices/system/cpu/cpufreq/boost
	cpupower frequency-set --max 3000MHz
	cpupower frequency-set --min 500MHz
	cpupower frequency-set --governor schedutil
	[ -f /opt/bin/nvidia-smi ] && {
		nvidia-smi -lgc 210,800
		nvidia-smi -lmc 400,820
	}
}

case $1 in

	"performance") performance;;
	"balanced") balanced;;
	"powersave") powersave;;
	*) echo "usage: $0 [performance|balanced|powersave]";;
esac
