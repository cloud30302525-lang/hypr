#!/bin/sh
set -Eeuo pipefail
trap 'echo "✘ Error at line $LINENO"; exit 1' ERR

[ "$(id -u)" -ne 0 ] || { echo "✘ Do not run with sudo"; exit 1; }

# ─── Config ─────────────────────────────────────────────
INSTALL_PKGS=1

HOME_CFG="$HOME/.config"
DOTS="$HOME/hyprend"
SRC="$HOME/hypr"

EDID_SRC="$SRC/edid75.bin"
EDID_DST="/lib/firmware/edid/edid75.bin"
GRUB="/etc/default/grub"
EDID_PARAM="drm.edid_firmware=DVI-D-1:edid/edid75.bin"

FF_PROFILES="$HOME/.mozilla/firefox"
FF_SRC="$SRC/firefox"
FF_DST="$DOTS/firefox"
FF_PROFILE_NAME="default-release"

# ─── Helpers ────────────────────────────────────────────
ok() { echo " $*"; }
die() { echo "✘ $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Missing: $1"; }
sudo_init() { sudo -v; }
confirm() { read -rp "$1 [y/N]: " r; case "$r" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac; }

force_link() { rm -rf "$2"; ln -s "$1" "$2"; }

link_dir() {
  [ -d "$1" ] || return
  mkdir -p "$2"
  find "$1" -mindepth 1 -maxdepth 1 -print | while IFS= read -r f; do
    force_link "$f" "$2/$(basename "$f")"
  done
}

# ─── Checks ─────────────────────────────────────────────
need xdg-user-dirs-update
need gsettings
need hyprctl
[ "$INSTALL_PKGS" -eq 0 ] || need paru

# ─── Packages ───────────────────────────────────────────
if [ "$INSTALL_PKGS" -eq 1 ]; then
  ok "Packages"
  paru -S --needed --noconfirm \
    waybar rofi wl-clip-persist cliphist swaync hyprpolkitagent hyprlock \
    qt6ct qt5ct nwg-look adw-gtk-theme papirus-icon-theme sddm-silent-theme-git \
    swaybg waypaper capitaine-cursors ttf-jetbrains-mono-nerd noto-fonts \
    slurp grim hyprpicker thunar engrampa thunar-archive-plugin \
    gvfs tumbler geany geany-plugins imv mpv keyd wireguard-tools \
    telegram-desktop mission-center onlyoffice-bin
fi

# ─── Locale ─────────────────────────────────────────────
ok "Locale"
sudo_init
sudo localectl set-locale ru_RU.UTF-8

# ─── Folders ────────────────────────────────────────────
ok "Folders"
thunar -q ; pkill xfconfd
LANG=en_US.UTF-8 xdg-user-dirs-update --force
rm -rf "$HOME"/{Music,Pictures,Public,Templates,Videos}
mkdir -p "$HOME/Box/screen"

# ─── Hyprend ────────────────────────────────────────────
ok "Hyprend"
mkdir -p "$DOTS"
cp -a "$SRC/config/." "$DOTS/" 2>/dev/null || :
find "$DOTS" -type f -name '*.sh' -exec chmod +x {} +
shopt -s nullglob
imgs=("$HOME"/hypr/img.*)
shopt -u nullglob
(( ${#imgs[@]} )) && cp -a "${imgs[@]}" "$HOME/Box/"

# ─── GTK Bookmarks ──────────────────────────────────────
ok "Bookmarks"
GTK_BM="$HOME_CFG/gtk-3.0/bookmarks"
mkdir -p "$(dirname "$GTK_BM")"
for p in "$HOME/Downloads" "$HOME/Box" "$HOME/Box/screen" "$DOTS" "$DOTS/hypr"; do
  [ -d "$p" ] && echo "file://$p $(basename "$p")"
done > "$GTK_BM"

# ─── Config Links ───────────────────────────────────────
ok "Links"
for d in "$DOTS"/*; do
  [ -d "$d" ] || continue
  case "$(basename "$d")" in rule|firefox) continue ;; esac
  link_dir "$d" "$HOME_CFG/$(basename "$d")"
done

# ─── MIME ───────────────────────────────────────────────
ok "MIME"
mkdir -p "$HOME_CFG"
cat > "$HOME_CFG/mimeapps.list" <<EOF
[Default Applications]
inode/directory=thunar.desktop
text/plain=geany.desktop
text/*=geany.desktop
application/x-shellscript=geany.desktop
application/xml=geany.desktop
application/xhtml+xml=geany.desktop
application/json=geany.desktop
image/png=imv-dir.desktop
image/jpeg=imv-dir.desktop
image/webp=imv-dir.desktop
video/mp4=mpv.desktop
video/x-matroska=mpv.desktop
EOF

# ─── Rules ──────────────────────────────────────────────
ok "Rules"
sudo install -Dm644 "$DOTS/rule/keyd" /etc/keyd/default.conf
sudo install -Dm644 "$DOTS/rule/ovpn" /etc/polkit-1/rules.d/49-openvpn.rules
sudo install -Dm644 "$DOTS/rule/sddm" /etc/sddm.conf
sudo install -Dm644 "$DOTS/rule/sddmt" /usr/share/sddm/themes/silent/metadata.desktop
sudo systemctl enable --now keyd

# ─── GTK ────────────────────────────────────────────────
ok "GTK"
gsettings set org.gnome.desktop.interface font-name 'Noto Sans Medium 10'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
hyprctl reload >/dev/null 2>&1 || :

# ─── EDID / GRUB ────────────────────────────────────────
if [ -f "$EDID_SRC" ] && confirm "Install EDID and update grub?"; then
  sudo install -Dm644 "$EDID_SRC" "$EDID_DST"

  if ! grep -q "$EDID_PARAM" "$GRUB"; then
    sudo sed -i \
      -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=')([^']*)'|\1\2 $EDID_PARAM'|" \
      "$GRUB"
  fi

  sudo grub-mkconfig -o /boot/grub/grub.cfg
  ok "EDID installed"
else
  ok "EDID skipped"
fi

# ─── Firefox ────────────────────────────────────────────
need firefox
[ -d "$FF_SRC" ] || die "Firefox config not found"

if confirm "Reset Firefox profiles and apply config? THIS WILL DELETE ALL FIREFOX PROFILES"; then
  pkill -x firefox >/dev/null 2>&1 || :
  rm -rf "$FF_PROFILES"
  mkdir -p "$FF_PROFILES"

  firefox >/dev/null 2>&1 &
  for _ in $(seq 1 20); do [ -f "$FF_PROFILES/profiles.ini" ] && break; sleep 0.5; done
  pkill -x firefox >/dev/null 2>&1 || :

  PROFILE_DIR=$(awk -v n="$FF_PROFILE_NAME" '
    $0=="Name="n {f=1}
    f && /^IsRelative=1/ {rel=1}
    f && /^Path=/ {sub("Path=", "", $0); print (rel?ENVIRON["HOME"]"/.mozilla/firefox/":"")$0; exit}
  ' "$FF_PROFILES/profiles.ini")

  [ -d "$PROFILE_DIR" ] || die "Profile dir not found"

  mkdir -p "$FF_DST"
  cp -a "$FF_SRC/." "$FF_DST/"
  ln -sfn "$FF_DST/user.js" "$PROFILE_DIR/user.js"
  ln -sfn "$FF_DST/chrome" "$PROFILE_DIR/chrome"

  ok "Firefox ready → firefox -P $FF_PROFILE_NAME"
else
  ok "Firefox skipped"
fi
