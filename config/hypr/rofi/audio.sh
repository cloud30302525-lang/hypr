#!/usr/bin/env bash
set -euo pipefail

P=$(playerctl -l 2>/dev/null | head -n1)
[[ -z $P ]] && exit 0

read -r S A T <<<"$(playerctl -p "$P" metadata --format '{{status}} {{artist}} {{title}}')"
I=$([[ $S == Playing ]] && echo "" || echo "")

printf "󰒮\n%s\n󰒭" "$I" | rofi -dmenu -i -format i \
    -selected-row 1 \
    -mesg "<span size='small'><b>$A</b></span> - <span size='small'>$T</span>" \
    -theme "$HOME/.config/hypr/rofi/config.rasi" \
    -theme-str '
        window { width: 300px; }
        mainbox { children: [message, listview]; spacing: 18px; }
        element-text { horizontal-align: 0.5; }
        element { padding: 8px; }
        message { margin: 6px; }
        listview { lines: 1; columns: 3; }
        configuration {
            show-icons: false;
            kb-move-char-back: "Left";
            kb-move-char-forward: "Right";
        }' |
{
    read -r IDX
    case $IDX in
        0) playerctl -p "$P" previous ;;
        1) playerctl -p "$P" play-pause ;;
        2) playerctl -p "$P" next ;;
    esac
}
