#!/usr/bin/env bash

VPN="$HOME/Box"
OPENVPN=/usr/bin/openvpn
CACHE=/tmp/vpn_ip.cache
THEME=$HOME/.config/hypr/rofi/themes/vpn.rasi

ACTIVE=$(pgrep openvpn >/dev/null &&
    ps -C openvpn -o args= |
    sed -n 's/.*--config \([^ ]*\).*/\1/p' |
    xargs -r basename | head -1)

# ipinfo в фоне
(
    curl -fsSL --max-time 2 ipinfo.io/json |
    jq -r '"󰩟  \(.ip//"…")\n󰍎  \(.city//"…"), \(.country//"…")"' \
    > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
) & disown

MESG=$(cat "$CACHE" 2>/dev/null || printf "󰩟  …\n󰍎  …")

mapfile -t CFG < <(ls "$VPN"/*.ovpn 2>/dev/null | sort) || exit
(( ${#CFG[@]} )) || exit

MENU=() ; SEL=0
for i in "${!CFG[@]}"; do
    N=$(basename "${CFG[$i]}")
    [[ $N == "$ACTIVE" ]] && MENU+=("●  $N") && SEL=$i || MENU+=("   $N")
done
[[ $ACTIVE ]] && MENU+=("   Disconnect") || MENU+=("●  Disconnect")

IDX=$(printf "%s\n" "${MENU[@]}" | rofi -dmenu -i \
    -p OpenVPN -selected-row "$SEL" \
    -format i -mesg "$MESG" -theme "$THEME")

[[ -z $IDX ]] && exit

pkexec killall openvpn 2>/dev/null

(( IDX == ${#CFG[@]} )) || pkexec "$OPENVPN" --config "${CFG[$IDX]}" --daemon
