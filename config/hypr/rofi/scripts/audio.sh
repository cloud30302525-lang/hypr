#!/bin/bash

PLAYER=$(playerctl -l 2>/dev/null | head -n1) || exit 0
[ -z "$PLAYER" ] && exit 0

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
TITLE=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)
ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)

ICON_PREV="󰒮"
ICON_NEXT="󰒭"
ICON_PLAY=$([[ $STATUS == Playing ]] && echo "" || echo "")

MESG="<span size='small'><b>$ARTIST</b></span> - <span size='small'>$TITLE</span>"

IDX=$(printf "%s\n" "$ICON_PREV" "$ICON_PLAY" "$ICON_NEXT" | rofi -dmenu -i \
    -columns 3 \
    -selected-row 1 \
    -format i \
    -p "" \
    -mesg "$MESG" \
    -theme ~/.config/hypr/rofi/themes/audio.rasi)

case "$IDX" in
    0) playerctl -p "$PLAYER" previous ;;
    1) playerctl -p "$PLAYER" play-pause ;;
    2) playerctl -p "$PLAYER" next ;;
esac
