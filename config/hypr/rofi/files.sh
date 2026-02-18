#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------

HISTORY="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-opened-files"
MAX_HISTORY=100
ROFI_THEME="$HOME/.config/hypr/rofi/config.rasi"
EDITOR=geany

mkdir -p "${HISTORY%/*}"
touch "$HISTORY"

# ---------------------------------------------------------------------------
# Icons
# ---------------------------------------------------------------------------

icon_for() {
    [[ -L $1 ]] && echo "󰌷" && return
    [[ -d $1 ]] && echo "󰉋" || echo "󰈔"
}

# ---------------------------------------------------------------------------
# History
# ---------------------------------------------------------------------------

update_history() {
    { grep -Fxv -- "$1" "$HISTORY" 2>/dev/null || true; echo "$1"; } \
        | tail -n "$MAX_HISTORY" >"$HISTORY.tmp"
    mv "$HISTORY.tmp" "$HISTORY"
}

# ---------------------------------------------------------------------------
# Text file check
# ---------------------------------------------------------------------------

is_text_file() {
    [[ $(file --mime-type -Lb -- "$1") == inode/x-empty ]] || \
    [[ $(file --mime-encoding -Lb -- "$1") != binary ]]
}

# ---------------------------------------------------------------------------
# fd excludes
# ---------------------------------------------------------------------------

FD_EXCLUDES=(
    --exclude .git
    --exclude .cache/mozilla
    --exclude .mozilla/firefox/*/cache*
)

# ---------------------------------------------------------------------------
# Build list
# ---------------------------------------------------------------------------

RESULT=$(
    {
        tac "$HISTORY" 2>/dev/null | while read -r f; do
            [[ -e $f ]] && printf "%s  %s\n" "$(icon_for "$f")" "${f#$HOME/}"
        done

        fd . "$HOME/.config" --hidden "${FD_EXCLUDES[@]}" 2>/dev/null \
            | sed "s|^$HOME/||"

        fd . "$HOME" --hidden "${FD_EXCLUDES[@]}" --exclude .config 2>/dev/null \
            | sed "s|^$HOME/||"
    } | awk '!seen[$0]++' | rofi -dmenu -i \
        -p "  Files" \
        -theme "$ROFI_THEME" \
        -theme-str '
            window { width: 500px; }
            configuration {
                kb-accept-entry: "Return";
                show-icons: false;
            }'
)

# ---------------------------------------------------------------------------
# Open
# ---------------------------------------------------------------------------

[[ -z $RESULT ]] && exit 0

FULL_PATH="$HOME/${RESULT#*  }"
update_history "$FULL_PATH"

if is_text_file "$FULL_PATH"; then
    "$EDITOR" "$FULL_PATH" &>/dev/null &
    hyprctl dispatch focuswindow class:$(basename "$EDITOR") &>/dev/null || true
else
    xdg-open "$FULL_PATH" &>/dev/null &
fi
