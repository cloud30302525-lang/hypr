#!/usr/bin/env bash
set -euo pipefail

# ───── config ─────
HISTORY="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-opened-files"
MAX_HISTORY=100
ROFI_THEME="$HOME/.config/hypr/rofi/themes/search.rasi"
EDITOR="geany"

TEXT_EXTENSIONS=(
  txt json jsonc yaml yml toml md sh conf
)

mkdir -p "${HISTORY%/*}"
touch "$HISTORY"

# ───── functions ─────
is_text_file() {
  local file="$1"
  [[ -d "$file" ]] && return 1

  local ext="${file##*.}"
  [[ "$file" != *.* ]] && return 0

  for e in "${TEXT_EXTENSIONS[@]}"; do
    [[ "$ext" == "$e" ]] && return 0
  done

  head -n 1 "$file" 2>/dev/null | grep -q '^#!'
}

open_file() {
  local target="$1"

  if [[ -d "$target" ]]; then
    xdg-open "$target" &>/dev/null &
  elif is_text_file "$target"; then
    "$EDITOR" "$target" &>/dev/null &
  else
    xdg-open "$target" &>/dev/null &
  fi
}

update_history() {
  {
    grep -Fxv "$1" "$HISTORY" || true
    echo "$1"
  } | tail -n "$MAX_HISTORY" >"$HISTORY.tmp"

  mv "$HISTORY.tmp" "$HISTORY"
}

# ───── rofi ─────
RESULT="$(
  {
    tac "$HISTORY" 2>/dev/null | while read -r f; do
      [[ -e "$f" ]] && echo "$f"
    done

    fd . "$HOME/.config" --hidden --exclude .git
    fd . "$HOME" --hidden --exclude .git --exclude .config
  } |
  awk '!seen[$0]++' |
  rofi -dmenu -i -p "Поиск файлов" -theme "$ROFI_THEME"
)"

[[ -z "$RESULT" ]] && exit 0

update_history "$RESULT"
open_file "$RESULT"
