#!/usr/bin/env bash

cliphist list \
  | rofi -dmenu \
      -p "󱉨  Clipboard" \
      -theme ~/.config/hypr/rofi/themes/search.rasi \
      -display-columns 2 \
  | cliphist decode \
  | wl-copy
