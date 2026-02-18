#!/usr/bin/env bash

LOCK="/tmp/screenshot.lock"
exec 9>"$LOCK" || exit 1
flock -n 9 || exit 1

DIR="$HOME/Box/screen"
mkdir -p "$DIR"

shopt -s nullglob
NUM=$(find "$DIR" -maxdepth 1 -name "[0-9]*.png" -printf "%f\n" | sort -n | tail -1 | cut -d. -f1)
NUM=$(( ${NUM:-0} + 1 ))
FILE="$DIR/$NUM.png"

if [[ "$1" == "full" ]]; then
    grim "$FILE"
else
    G=$(slurp) || exit 0
    sleep 0.2
    grim -g "$G" "$FILE"
fi

wl-copy < "$FILE"

(
    exec 9>&-
    R=$(notify-send -a "Screenshot" -i "$FILE" "  Снимок #$NUM" "$DIR" --action="default=Open" --wait)
    [[ "$R" == "default" ]] && xdg-open "$DIR" >/dev/null 2>&1 &
) >/dev/null 2>&1 &

echo " Скриншот $NUM.png готов!"
