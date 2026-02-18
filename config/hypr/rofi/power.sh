#!/usr/bin/env bash
set -euo pipefail

printf "   Logout\n   Suspend\n   Reboot\n   Poweroff" | rofi -dmenu -i \
    -theme "$HOME/.config/hypr/rofi/config.rasi" \
    -theme-str '
        window { width: 200px; }
        mainbox { children: [listview]; }
        listview { margin: 6px; lines: 4; }
        element-text { margin: 3px 39px; }
        configuration { show-icons: false; }' |
case $(cat) in
    *Logout)   hyprctl dispatch exit ;;
    *Suspend) hyprlock & systemctl suspend ;;
    *Reboot)  systemctl reboot ;;
    *Poweroff) systemctl poweroff ;;
esac
