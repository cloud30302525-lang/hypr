#!/usr/bin/env bash
set -euo pipefail

# ───── config ─────
HISTORY="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-opened-files"
MAX_HISTORY=100
ROFI_THEME="$HOME/.config/hypr/rofi/themes/search.rasi"
EDITOR="geany"

# Список расширений текстовых файлов
TEXT_EXTENSIONS=(
  txt json jsonc yaml yml toml md sh conf css
)

# Создаем историю, если нет
mkdir -p "${HISTORY%/*}"
touch "$HISTORY"

# ───── functions ─────
# Проверка, является ли файл текстовым
is_text_file() {
  local file="$1"
  [[ -d "$file" ]] && return 1

  local ext="${file##*.}"
  [[ "$file" != *.* ]] && return 0

  for e in "${TEXT_EXTENSIONS[@]}"; do
    [[ "$ext" == "$e" ]] && return 0
  done

  # Проверка shebang
  head -n 1 "$file" 2>/dev/null | grep -q '^#!'
}

# Выбор иконки для файла/папки
icon_for() {
  local f="$1"
  [[ -d "$f" ]] && echo "󰉋" && return    # folder
  is_text_file "$f" && echo "󰈙" && return # text file
  echo "󰈔"                                # generic file
}

# Открытие файла/папки
open_file() {
  local target="$1"

  if [[ -d "$target" ]]; then
    xdg-open "$target" &>/dev/null &
    exit 0
  fi

  if is_text_file "$target"; then
    "$EDITOR" "$target" &>/dev/null &
    sleep 0.15
    # фокусируем окно Geany
    hyprctl dispatch focuswindow class:geany &>/dev/null
  else
    xdg-open "$target" &>/dev/null &
  fi
}

# Обновление истории
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
    # История
    tac "$HISTORY" 2>/dev/null | while IFS= read -r f; do
      [[ -e "$f" ]] || continue
      rel="${f#$HOME/}"  # путь относительно home
      printf "%s %s\n" "$(icon_for "$f")" "$rel"
    done

    # Поиск в .config
    fd . "$HOME/.config" --hidden --exclude .git | sed "s|$HOME/||"

    # Поиск в home, кроме .config
    fd . "$HOME" --hidden --exclude .git --exclude .config | sed "s|$HOME/||"
  } |
  awk '!seen[$0]++' |
  rofi -dmenu -i -p "Поиск файлов" -theme "$ROFI_THEME"
)"

[[ -z "$RESULT" ]] && exit 0

# Убираем иконку
RESULT="${RESULT#* }"

# Получаем полный путь для открытия и обновления истории
FULL_PATH="$HOME/$RESULT"

update_history "$FULL_PATH"
open_file "$FULL_PATH"
