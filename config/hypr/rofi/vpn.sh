#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Paths & binaries
# ---------------------------------------------------------------------------

VPN="$HOME/Box"
OPENVPN=/usr/bin/openvpn
WG=/usr/bin/wg-quick
THEME="$HOME/.config/hypr/rofi/config.rasi"
CACHE=/tmp/vpn_ip.cache

# ---------------------------------------------------------------------------
# Capabilities
# ---------------------------------------------------------------------------

HAVE_WG=false
command -v wg >/dev/null && command -v wg-quick >/dev/null && HAVE_WG=true

# ---------------------------------------------------------------------------
# Detect active OpenVPN
# ---------------------------------------------------------------------------

OVPN_PID=$(pgrep -xo openvpn || true)
OVPN_CFG=""

[[ $OVPN_PID ]] && \
OVPN_CFG=$(ps -p "$OVPN_PID" -o args= |
    sed -n 's/.*--config \([^ ]*\).*/\1/p')

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
# VPN type
# ---------------------------------------------------------------------------

VPN_TYPE=Disconnected
[[ $OVPN_CFG ]] && VPN_TYPE=OpenVPN
[[ $WG_CFG ]]   && VPN_TYPE=WireGuard

# ---------------------------------------------------------------------------
# Message cache (never empty)
# ---------------------------------------------------------------------------

DEFAULT_MSG=$'󰩟	…\n󰍎	…\n󰖂	'"$VPN_TYPE"

if [[ -s $CACHE ]]; then
    MESG=$(<"$CACHE")
else
    MESG="$DEFAULT_MSG"
    printf "%s\n" "$DEFAULT_MSG" >"$CACHE"
fi

# ---------------------------------------------------------------------------
# Async IP refresh
# ---------------------------------------------------------------------------

(
    curl -fsSL --max-time 2 ipinfo.io/json |
    jq -r --arg v "$VPN_TYPE" \
    '"󰩟	\(.ip//"…")\n󰍎	\(.city//"…"), \(.country//"…")\n󰖂	\($v)"' \
    >"$CACHE.tmp" &&
    [[ -s "$CACHE.tmp" ]] &&
    mv "$CACHE.tmp" "$CACHE"
) & disown

# ---------------------------------------------------------------------------
# Collect configs
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
    f="${CFG[$i]}"
    name=$(basename "$f")

    if [[ $f == "$OVPN_CFG" || $f == "$WG_CFG" ]]; then
        MENU+=("	$name")
        SEL=$i
    else
        MENU+=("	$name")
    fi
done

[[ $OVPN_CFG || $WG_CFG ]] \
    && MENU+=("	Disconnect") \
    || MENU+=("	Disconnect")

# ---------------------------------------------------------------------------
# Rofi
# ---------------------------------------------------------------------------

IDX=$(printf "%s\n" "${MENU[@]}" | rofi -dmenu -i \
    -p VPN -selected-row "$SEL" -format i -mesg "$MESG" \
    -theme "$THEME" \
    -theme-str '
        window { width: 250px; }
        mainbox { children: [listview, message]; spacing: -6px; }
        listview { margin: 6px; fixed-height: false; }
        message { margin: 6px 15px; }
        configuration { show-icons: false; }'
)

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

# ---------------------------------------------------------------------------
# No-op if already active
# ---------------------------------------------------------------------------

[[ $SEL_FILE == "$OVPN_CFG" || $SEL_FILE == "$WG_CFG" ]] && exit 0

# ---------------------------------------------------------------------------
# Stop current VPN
# ---------------------------------------------------------------------------

[[ $OVPN_PID ]] && pkexec kill "$OVPN_PID"
[[ $WG_IFACE ]] && pkexec "$WG" down "$VPN/$WG_IFACE.conf"

# ---------------------------------------------------------------------------
# Start selected VPN
# ---------------------------------------------------------------------------

case "$SEL_NAME" in
    *.ovpn) pkexec "$OPENVPN" --config "$SEL_FILE" --daemon ;;
    *.conf) pkexec "$WG" up "$SEL_FILE" ;;
esac
