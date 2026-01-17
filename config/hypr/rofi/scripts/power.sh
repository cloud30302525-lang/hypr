#!/bin/bash

options="   Logout
   Reboot
   Poweroff"

choice=$(echo -e "$options" | rofi -dmenu -theme ~/.config/hypr/rofi/themes/power.rasi -i -p "Power")

case "$choice" in
  *Logout)   hyprctl dispatch exit ;;
  *Reboot)   systemctl reboot ;;
  *Poweroff) systemctl poweroff ;;
esac
