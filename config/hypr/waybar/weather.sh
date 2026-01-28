#!/bin/sh

# =========================
# Настройки
# =========================
API="https://api.openweathermap.org/data/2.5/weather"
KEY="e434b5435a979de6e155570590bee89b"
CITY="Novosibirsk"
UNITS="metric"
SYMBOL="°"
TIMEOUT=4
CACHE="/tmp/waybar_weather.json"
CACHE_TTL=300

# =========================
# Иконки
# =========================
get_icon() {
    case "$1" in
        01d) echo "" ;;
        01n) echo "" ;;
        02d) echo "" ;;
        02n) echo "" ;;
        03*|04*) echo "" ;;
        09*) echo "" ;;
        10d) echo "" ;;
        10n) echo "" ;;
        11*) echo "" ;;
        13*) echo "" ;;
        50*) echo "" ;;
        *) echo "" ;;
    esac
}

# =========================
# Кэш
# =========================
now=$(date +%s)
if [ -f "$CACHE" ]; then
    mtime=$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)
    [ $((now - mtime)) -lt $CACHE_TTL ] && weather=$(cat "$CACHE")
fi

# =========================
# Запрос
# =========================
if [ -z "$weather" ]; then
    weather=$(curl -sf --compressed --max-time "$TIMEOUT" \
        "$API?appid=$KEY&q=$CITY&units=$UNITS") || {
        printf '{"text":"  --","tooltip":"Нет данных"}\n'
        exit 1
    }
    printf '%s' "$weather" > "$CACHE"
fi

# =========================
# Парсинг
# =========================
set -- $(printf '%s' "$weather" | jq -r '
    .main.temp,
    .main.feels_like,
    .weather[0].icon
')

temp=${1%.*}
feels=${2%.*}
icon_code=$3

# =========================
# Вывод
# =========================
icon=$(get_icon "$icon_code")

printf '{"text":"%-4s %s%s","tooltip":"Ощущается как %s%s"}\n' \
    "$icon" "$temp" "$SYMBOL" "$feels" "$SYMBOL"
