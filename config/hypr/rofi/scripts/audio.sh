#!/bin/bash

PLAYER=$(playerctl -l 2>/dev/null | head -n1) || exit 0
[ -z "$PLAYER" ] && exit 0

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null) || exit 0

META=$(playerctl -p "$PLAYER" metadata --format '{{artist}}|{{title}}')
ARTIST=${META%%|*}
TITLE=${META#*|}

ICON_PLAY=$([ "$STATUS" = Playing ] && echo "" || echo "")

IDX=$(printf "󰒮\n%s\n󰒭" "$ICON_PLAY" | rofi -dmenu -i \
  -format i \
  -mesg "<span size='small'><b>$ARTIST</b></span> - <span size='small'>$TITLE</span>" \
  -theme ~/.config/hypr/rofi/themes/audio.rasi)

case $IDX in
  0) playerctl -p "$PLAYER" previous ;;
  1) playerctl -p "$PLAYER" play-pause ;;
  2) playerctl -p "$PLAYER" next ;;
esac
