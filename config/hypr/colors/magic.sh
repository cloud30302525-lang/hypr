#!/usr/bin/env bash

## --- Конфигурация путей ---
CONF_DIR="$HOME/hyprend"
CSS_FILE="$CONF_DIR/hypr/colors/colors.css"
RASI_FILE="$CONF_DIR/hypr/rofi/colors.rasi"
ALACRITTY_FILE="$CONF_DIR/alacritty/alacritty.toml"
GEANY_FILE="$CONF_DIR/geany/colorschemes/theme.conf"
QT5_FILE="$CONF_DIR/qt5ct/colors/theme.conf"
QT6_FILE="$CONF_DIR/qt6ct/colors/theme.conf"
WAYBAR_DIR="$CONF_DIR/hypr/waybar"
POLKIT_BIN="/usr/lib/hyprpolkitagent/hyprpolkitagent"
POLKIT_NAME=$(basename "$POLKIT_BIN")
FIREFOX_FILE="$CONF_DIR/firefox/chrome/bin/colors.css"

[[ ! -f "$CSS_FILE" ]] && exit 1

## --- Извлечение и парсинг цветов ---
eval "$(sed -nE "
    s/.*bg[[:space:]]+rgb\(([^)]+)\).*/rgb_bg='\1'/p;
    s/.*bg2[[:space:]]+rgb\(([^)]+)\).*/rgb_bg2='\1'/p;
    s/.*bg3[[:space:]]+rgb\(([^)]+)\).*/rgb_bg3='\1'/p;
    s/.*border[[:space:]]+rgb\(([^)]+)\).*/rgb_border='\1'/p;
    s/.*b-text[[:space:]]+rgb\(([^)]+)\).*/rgb_text_main='\1'/p;
    s/.*text-lt[[:space:]]+rgb\(([^)]+)\).*/rgb_lt='\1'/p;
    s/.*text-lt2[[:space:]]+rgb\(([^)]+)\).*/rgb_lt2='\1'/p;
    s/.*accent[[:space:]]+rgb\(([^)]+)\).*/rgb_accent='\1'/p;
    s/.*bg-swaync[[:space:]]+alpha\(@bg,[[:space:]]*([0-9.]+)\).*/alpha_bg='\1'/p;
    s/.*bd[[:space:]]+alpha\(@border,[[:space:]]*([0-9.]+)\).*/alpha_bd='\1'/p;
    s/.*text[[:space:]]+alpha\(@b-text,[[:space:]]*([0-9.]+)\).*/alpha_text='\1'/p;
" "$CSS_FILE")"

rgb_to_hex() {
    IFS=',' read -r r g b <<< "${1:-0,0,0}"
    printf "%02x%02x%02x" "$r" "$g" "$b"
}

HEX_BG=$(rgb_to_hex "$rgb_bg")
HEX_FG=$(rgb_to_hex "$rgb_text_main")
HEX_SEL_BG=$(rgb_to_hex "${rgb_bg3:-20,20,20}")

IFS=',' read -r r g b <<< "${rgb_bg:-0,0,0}"
HEX_CUR_LINE=$(printf "%02x%02x%02x" $((r<241?r+15:255)) $((g<241?g+15:255)) $((b<241?b+15:255)))

ARGB_BG="ff$HEX_BG"
ARGB_FG="ff$HEX_FG"
ARGB_HL="ff$(rgb_to_hex "${rgb_bg3:-$rgb_border}")"
ARGB_DIS="88$HEX_FG"

IFS=',' read -r r g b <<< "$(echo "$rgb_bg3" | tr -d ' ')"
r_bd=$(awk "BEGIN { v=int($r*1.5); print (v>255?255:v) }")
g_bd=$(awk "BEGIN { v=int($g*1.5); print (v>255?255:v) }")
b_bd=$(awk "BEGIN { v=int($b*1.5); print (v>255?255:v) }")

rgb_bd_rofi="$r_bd,$g_bd,$b_bd"

## --- Обновление конфигураций файлов ---
cat > "$RASI_FILE" <<EOF
* {
    bg: rgba($rgb_bg, $alpha_bg);
    bg3: rgba($rgb_bg3, 0.4);
    bd: rgba($rgb_bd_rofi, $alpha_bg);
    text: rgba($rgb_text_main, $alpha_text);
    text-lt: rgb($rgb_lt);
    text-lt2: rgb(${rgb_lt2:-$rgb_lt});
}
EOF

[[ -f "$ALACRITTY_FILE" ]] && sed -i "s/background = \".*\"/background = \"#$HEX_BG\"/; s/foreground = \".*\"/foreground = \"#$HEX_FG\"/" "$ALACRITTY_FILE"

[[ -f "$GEANY_FILE" ]] && sed -i -E "
    s/^default=.*/default=#$HEX_FG;#$HEX_BG;false;false/; 
    s/^current_line=.*/current_line=#$HEX_FG;#$HEX_CUR_LINE;true/; 
    s/^selection=.*/selection=#$HEX_FG;#$HEX_SEL_BG;false;true/;
    s/^caret=.*/caret=#$HEX_FG;#$HEX_FG;false/; 
    s/^margin_line_number=.*/margin_line_number=#$HEX_FG;#$HEX_BG/; 
    s/^margin_folding=.*/margin_folding=#$HEX_FG;#$HEX_BG/
" "$GEANY_FILE"

active="#$ARGB_FG, #$ARGB_HL, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_FG, #$ARGB_FG, #$ARGB_FG, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_HL, #$ARGB_FG, #$ARGB_FG, #$ARGB_FG, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_FG, #$ARGB_FG"
disabled="#$ARGB_DIS, #$ARGB_HL, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_DIS, #$ARGB_FG, #$ARGB_DIS, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_HL, #$ARGB_FG, #$ARGB_FG, #$ARGB_FG, #$ARGB_BG, #$ARGB_BG, #$ARGB_BG, #$ARGB_FG, #$ARGB_FG"

for qt_conf in "$QT5_FILE" "$QT6_FILE"; do
    [[ -f "$qt_conf" ]] && sed -i "s|^active_colors=.*|active_colors=$active|; s|^inactive_colors=.*|inactive_colors=$active|; s|^disabled_colors=.*|disabled_colors=$disabled|" "$qt_conf"
done

## --- Обновление Firefox ---
if [[ -f "$FIREFOX_FILE" ]]; then
    sed -i -E "
        s/(--dtui-theme-main-color:[[:space:]]*)[0-9,[:space:]]+;/\1$rgb_bg;/;
        s/(--dtui-theme-secondary-color:[[:space:]]*)[0-9,[:space:]]+;/\1$rgb_bg3;/;
        s/(--dtui-theme-accent-color:[[:space:]]*)[0-9,[:space:]]+;/\1$rgb_accent;/;
        s/(--dtui-theme-text-color:[[:space:]]*)[0-9,[:space:]]+;/\1$rgb_text_main;/;
        s/(--dtui-theme-accent-link:[[:space:]]*)[0-9,[:space:]]+;/\1$rgb_lt;/;
        s/(--dtui-theme-border:[[:space:]]*)[0-9,[:space:]]+;/\1$rgb_border;/;
    " "$FIREFOX_FILE"
fi

## --- Перезапуск сервисов и Polkit ---
(
    swaync-client -rs && swaync-client -R
    pkill waybar && waybar -c "$WAYBAR_DIR/waybar.jsonc" -s "$WAYBAR_DIR/waybar.css"
    
    pkill -f "$POLKIT_NAME"
    while pgrep -f "$POLKIT_NAME" > /dev/null; do sleep 0.2; done
    "$POLKIT_BIN"
) > /dev/null 2>&1 &

echo " Цветовая схема успешно применена!"
