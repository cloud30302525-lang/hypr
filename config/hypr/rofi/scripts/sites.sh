#!/usr/bin/env bash

hyprctl switchxkblayout all 0

choice=$(printf "%s\n" \
"󰈹  Firefox" \
"  YouTube" \
"󰎁  Rezka" \
"󰝚  Music" \
"󰚩  ChatGPT" \
"  Arch" \
"󰣇  AUR" \
"  GitHub" \
| rofi -dmenu -p "Сайты" -i -matching fuzzy -theme ~/.config/hypr/rofi/themes/sites.rasi) || exit 0

case "$choice" in
  "󰈹  Firefox") firefox & exit 0 ;;
  "  YouTube")  url=https://youtube.com ;;
  "󰎁  Rezka")    url=https://rezka.fi/continue ;;
  "󰝚  Music")    url=https://music.yandex.ru ;;
  "󰚩  ChatGPT")  url=https://chatgpt.com ;;
  "  Arch")     url=https://archlinux.org/packages ;;
  "󰣇  AUR")      url=https://aur.archlinux.org/packages ;;
  "  GitHub")   url=https://github.com/cloud30302525-lang/hypr ;;
  *) exit 0 ;;
esac

firefox --new-tab "$url" &
hyprctl dispatch workspace 1
hyprctl dispatch focuswindow "class:^(firefox)$"
