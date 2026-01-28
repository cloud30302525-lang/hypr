#!/usr/bin/env bash
set -euo pipefail

VPN="$HOME/Box"
OPENVPN=/usr/bin/openvpn
WG=/usr/bin/wg-quick

CACHE=/tmp/vpn_ip.cache
THEME=$HOME/.config/hypr/rofi/themes/vpn.rasi

# ---------------------------------------------------------------------------
# Capabilities
# ---------------------------------------------------------------------------

HAVE_WG=false
command -v wg >/dev/null && command -v wg-quick >/dev/null && HAVE_WG=true

# ---------------------------------------------------------------------------
# Detect active OpenVPN
# ---------------------------------------------------------------------------

OVPN_PID=$(pgrep openvpn || true)
OVPN_CFG=""

if [[ $OVPN_PID ]]; then
    OVPN_CFG=$(ps -p "$OVPN_PID" -o args= |
        sed -n 's/.*--config \([^ ]*\).*/\1/p')
fi

# ---------------------------------------------------------------------------
# Detect active WireGuard
# ---------------------------------------------------------------------------

WG_IFACE=""
WG_CFG=""

if $HAVE_WG; then
    WG_IFACE=$(wg show interfaces 2>/dev/null | awk '{print $1}')
    [[ $WG_IFACE && -f "$VPN/$WG_IFACE.conf" ]] && WG_CFG="$VPN/$WG_IFACE.conf"
fi

# ---------------------------------------------------------------------------
# VPN type (for message box)
# ---------------------------------------------------------------------------

VPN_TYPE="Disconnected"
[[ $OVPN_CFG ]] && VPN_TYPE="OpenVPN"
[[ $WG_CFG   ]] && VPN_TYPE="WireGuard"

# ---------------------------------------------------------------------------
# Message box cache (never empty)
# ---------------------------------------------------------------------------

if [[ ! -f $CACHE ]]; then
    printf "󰩟	…\n󰍎	…\n󰖂	%s\n" "$VPN_TYPE" > "$CACHE"
fi

MESG=$(cat "$CACHE")

# async refresh (non-blocking)
(
    curl -fsSL --max-time 2 ipinfo.io/json |
    jq -r --arg vpn "$VPN_TYPE" \
    '"󰩟	\(.ip//"…")\n󰍎	\(.city//"…"), \(.country//"…")\n󰖂	\($vpn)"' \
    > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
) & disown

# ---------------------------------------------------------------------------
# Collect configs (hide .conf if WG unavailable)
# ---------------------------------------------------------------------------

CFG=()
while IFS= read -r f; do CFG+=("$f"); done < <(
    ls "$VPN"/*.ovpn 2>/dev/null
    $HAVE_WG && ls "$VPN"/*.conf 2>/dev/null
)

(( ${#CFG[@]} )) || exit 0

# ---------------------------------------------------------------------------
# Build menu
# ---------------------------------------------------------------------------

MENU=()
SEL=0

for i in "${!CFG[@]}"; do
    FILE="${CFG[$i]}"
    NAME=$(basename "$FILE")

    if [[ $FILE == "$OVPN_CFG" || $FILE == "$WG_CFG" ]]; then
        MENU+=("	$NAME")
        SEL=$i
    else
        MENU+=("	$NAME")
    fi
done

[[ $OVPN_CFG || $WG_CFG ]] \
    && MENU+=("	Disconnect") \
    || MENU+=("	Disconnect")

# ---------------------------------------------------------------------------
# Rofi
# ---------------------------------------------------------------------------

IDX=$(printf "%s\n" "${MENU[@]}" | rofi -dmenu -i \
    -p VPN -selected-row "$SEL" \
    -format i -mesg "$MESG" -theme "$THEME")

[[ -z $IDX ]] && exit 0

# ---------------------------------------------------------------------------
# Disconnect
# ---------------------------------------------------------------------------

if (( IDX == ${#CFG[@]} )); then
    [[ $OVPN_PID ]] && pkexec kill "$OVPN_PID"
    [[ $WG_IFACE ]] && pkexec "$WG" down "$VPN/$WG_IFACE.conf"
    exit 0
fi

SEL_FILE="${CFG[$IDX]}"
SEL_NAME=$(basename "$SEL_FILE")

# No-op if already active
[[ $SEL_FILE == "$OVPN_CFG" || $SEL_FILE == "$WG_CFG" ]] && exit 0

# ---------------------------------------------------------------------------
# Stop current VPN (race-free)
# ---------------------------------------------------------------------------

if [[ $OVPN_PID ]]; then
    pkexec kill "$OVPN_PID"
    while pgrep openvpn >/dev/null; do sleep 0.1; done
fi

if [[ $WG_IFACE ]]; then
    pkexec "$WG" down "$VPN/$WG_IFACE.conf"
    while wg show interfaces 2>/dev/null | grep -q .; do sleep 0.1; done
fi

# ---------------------------------------------------------------------------
# Start selected VPN
# ---------------------------------------------------------------------------

case "$SEL_NAME" in
    *.ovpn)
        pkexec "$OPENVPN" --config "$SEL_FILE" --daemon
        ;;
    *.conf)
        pkexec "$WG" up "$SEL_FILE"
        ;;
esac
