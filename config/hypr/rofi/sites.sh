#!/usr/bin/env bash
set -euo pipefail

web="firefox"

sites=(
  "󰈹    ${web^}|"
  "    YouTube|https://youtube.com"
  "󰎁    Rezka|https://rezka.fi/continue"
  "󰝚    Music|https://music.yandex.ru"
  "󱨃    Deepseek|https://chat.deepseek.com"
  "󰚩    ChatGPT|https://chatgpt.com"
  "    GitHub|https://github.com/cloud30302525-lang/hypr"
)

choice=$(printf '%s\n' "${sites[@]%%|*}" | rofi -dmenu -i \
    -theme "$HOME/.config/hypr/rofi/config.rasi" \
    -theme-str '
        window { width: 200px; }
        mainbox { children: [listview]; }
        listview { margin: 6px; lines: 7; }
        element-text { margin: 1px 0px; }
        configuration { show-icons: true; }'
) || exit 0

for i in "${!sites[@]}"; do
    [[ ${sites[i]%%|*} == "$choice" ]] && url=${sites[i]#*|} && break
done

$web --new-tab ${url:+ "$url"} &
