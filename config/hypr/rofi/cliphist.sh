#!/usr/bin/env bash
set -euo pipefail

cliphist list | rofi -dmenu -i \
    -p "󱉨  Clipboard" \
    -display-columns 2 \
    -theme "$HOME/.config/hypr/rofi/config.rasi" \
    -theme-str '
        window { width: 500px; }
        configuration {
            kb-accept-entry: "Return";
            show-icons: false;
        }' \
| cliphist decode \
| wl-copy
