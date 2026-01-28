#!/bin/bash

choice=$(echo -e "   Logout\n   Suspend\n   Reboot\n   Poweroff" | rofi -dmenu \
    -theme ~/.config/hypr/rofi/themes/power.rasi)

case "$choice" in
    *Logout)
        hyprctl dispatch exit
        ;;
    *Suspend)
        hyprlock &
        systemctl suspend
        ;;
    *Reboot)
        systemctl reboot
        ;;
    *Poweroff)
        systemctl poweroff
        ;;
esac
