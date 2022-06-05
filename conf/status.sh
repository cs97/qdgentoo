#!/bin/sh

date_formatted=$(date "+%a %F %H:%M")

battery_status='BAT: '$(cat /sys/class/power_supply/BAT0/capacity)'% '$(cat /sys/class/power_supply/BAT0/status)

volume_status='vol:'$(amixer -M get Master | grep "Left:" | cut -f 7,8 -d " ")

echo $volume_status $battery_status $date_formatted
