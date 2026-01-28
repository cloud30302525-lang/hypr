#!/usr/bin/env bash

LOCK=/tmp/screenshot.lock
exec 9>"$LOCK" || exit 0
flock -n 9 || exit 0

DIR="$HOME/Box/screen"
mkdir -p "$DIR"

NUM=$(ls "$DIR"/*.png 2>/dev/null | sed 's#.*/##; s/\.png//' | sort -n | tail -n 1)
NUM=$((NUM + 1))

FILE="$DIR/$NUM.png"

if [[ "$1" == full ]]; then
    grim "$FILE"
else
    GEOM=$(slurp)
    [[ -z "$GEOM" ]] && exit 0
    grim -g "$GEOM" "$FILE"
fi

wl-copy < "$FILE"

notify-send -a Screenshot -i "$FILE" "$(basename "$FILE")" "$FILE"
