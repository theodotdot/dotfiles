#!/bin/bash
 
res=$(echo "logout|reboot|shutdown" | rofi -sep "|" -dmenu -i -p 'Power Menu: ' "" -hide-scrollbar -eh 2 -opacity 100 -auto-select)
 
#if [ $res = "lock" ]; then
#    /home/khoaduccao/.config/lock.sh
#fi
if [ $res = "logout" ]; then
    pkill -KILL -u theotime
fi
if [ $res = "reboot" ]; then
    systemctl reboot
fi
if [ $res = "shutdown" ]; then
    systemctl poweroff
fi
exit 0
