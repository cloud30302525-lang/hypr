#!/usr/bin/env bash
set -euo pipefail

sites=(
  "󰈹    Firefox|"
  "    YouTube|https://youtube.com"
  "󰎁    Rezka|https://rezka.fi/continue"
  "󰝚    Music|https://music.yandex.ru"
  "󰚩    ChatGPT|https://chatgpt.com"
  "    Arch|https://archlinux.org/packages"
  "    GitHub|https://github.com/cloud30302525-lang/hypr"
)

choice=$(printf '%s\n' "${sites[@]%%|*}" | rofi -dmenu -i \
    -theme "$HOME/.config/hypr/rofi/config.rasi" \
    -theme-str '
        window { width: 200px; }
        mainbox { children: [listview]; }
        listview { margin: 6px; lines: 7; }
        element-text { margin: 1px 38px; }
        configuration { show-icons: false; }'
) || exit 0

for i in "${!sites[@]}"; do
    [[ ${sites[i]%%|*} == "$choice" ]] && url=${sites[i]#*|} && break
done

firefox --new-tab ${url:+ "$url"} &

hyprctl dispatch workspace 1
