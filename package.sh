#!/usr/bin/env bash
set -e

echo " Установка локали"
localectl set-locale ru_RU.UTF-8

echo " Установка пакетов"
paru -Syu --needed --noconfirm

PKGS=(
    waybar rofi wl-clip-persist cliphist mako hyprpolkitagent
    qt6ct qt5ct nwg-look adw-gtk-theme papirus-icon-theme swaybg capitaine-cursors ttf-jetbrains-mono-nerd noto-fonts
    slurp grim hyprpicker thunar engrampa thunar-archive-plugin gvfs tumbler
    geany geany-plugins imv mpv keyd
    telegram-desktop mission-center onlyoffice-bin
)
paru -S --needed --noconfirm "${PKGS[@]}"

echo " Настройка Thunar"
mkdir -p ~/Box/screen
xdg-mime default thunar.desktop inode/directory
LANG=en_US.UTF-8 xdg-user-dirs-update --force

echo " Hyprland config"
cp -a ~/hypr/config/. ~/.config/
chmod +x ~/.config/hypr/move.sh ~/.config/hypr/rofi/scripts/*.sh
chmod +x ~/.config/hypr/waybar/*.sh

gsettings set org.gnome.desktop.interface font-name 'Noto Sans Medium 10'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'

echo " Polkit openvpn"
sudo tee /etc/polkit-1/rules.d/49-openvpn.rules > /dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
       (action.lookup("command_line").includes("/usr/bin/openvpn") ||
        action.lookup("command_line").includes("killall openvpn"))) {
        return polkit.Result.YES;
    }
});
EOF

echo " Keyd"
sudo tee /etc/keyd/default.conf > /dev/null <<'EOF'
[ids]
*

[main]
capslock = layer(nav)

[nav]
w = up
a = left
s = down
d = right
EOF

sudo systemctl enable --now keyd

echo " Скрипт завершён!"
