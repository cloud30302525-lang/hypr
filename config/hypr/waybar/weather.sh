#!/usr/bin/env bash

URL="https://api.open-meteo.com/v1/forecast?latitude=55.03&longitude=82.92&current=temperature_2m,apparent_temperature,wind_speed_10m,weather_code&wind_speed_unit=ms&models=best_match&timezone=auto"

DATA=$(curl -sf --max-time 5 "$URL")

if [[ -z $DATA ]]; then
  echo '{"text":"󰖙  --°C"}'
  exit 0
fi

TEMP=$(jq -r '.current.temperature_2m | floor' <<<"$DATA")
FEELS=$(jq -r '.current.apparent_temperature | floor' <<<"$DATA")
WIND=$(jq -r '.current.wind_speed_10m' <<<"$DATA")
CODE=$(jq -r '.current.weather_code' <<<"$DATA")

case "$CODE" in
  0) ICON="󰖙" ;;
  1|2) ICON="󰖕" ;;
  3) ICON="󰖐" ;;
  45|48) ICON="󰖑" ;;
  51|53|55|61|63|65) ICON="󰖗" ;;
  66|67) ICON="󰙿" ;;
  71|73|75|77) ICON="󰖘" ;;
  80|81|82) ICON="󰖖" ;;
  95) ICON="󰖓" ;;
  96|99) ICON="󰙾" ;;
  *) ICON="󰖙" ;;
esac

printf '{"text":"%s  %s°C","tooltip":"Новосибирск\\nОщущается: %s°C\\nВетер: %s м/с"}\n' \
  "$ICON" "$TEMP" "$FEELS" "$WIND"
