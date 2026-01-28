#!/usr/bin/env bash
set -euo pipefail

hyprctl switchxkblayout all 0

sites=(
  "󰈹    Firefox|"
  "    YouTube|https://youtube.com"
  "󰎁    Rezka|https://rezka.fi/continue"
  "󰝚    Music|https://music.yandex.ru"
  "󰚩    ChatGPT|https://chatgpt.com"
  "    Arch|https://archlinux.org/packages"
  "    GitHub|https://github.com/cloud30302525-lang/hypr"
)

choice=$(printf '%s\n' "${sites[@]%%|*}" |
  rofi -dmenu -i -theme ~/.config/hypr/rofi/themes/sites.rasi
) || exit 0

for i in "${!sites[@]}"; do
  [[ "${sites[i]%%|*}" == "$choice" ]] && idx=$i && break
done

[[ -z "${idx:-}" ]] && exit 0

action="${sites[idx]#*|}"

firefox --new-tab ${action:+ "$action"} &

hyprctl dispatch workspace 1
hyprctl dispatch focuswindow "class:^(firefox)$"
