set -e

# == ru == #
localectl set-locale ru_RU.UTF-8

paru -Syu --needed --noconfirm

PKGS=(
	waybar # == bar == #
	rofi # == menu == #
	wl-clip-persist # == clipboard == #
	cliphist
	mako # == notifications == #
	hyprpolkitagent # == polkit == #
	qt6ct
	slurp # == screen == #
	grim
	hyprpicker
	nwg-look # == theme == #
	adw-gtk-theme
	papirus-icon-theme
	swaybg
	capitaine-cursors
	ttf-jetbrains-mono-nerd
	thunar # == thunar == #
	engrampa
	thunar-archive-plugin
	gvfs
	tumbler
	geany # == files == #
	imv
	mpv
	keyd # == wasd == #
)

paru -S --needed --noconfirm "${PKGS[@]}"

# == thunar == #
mkdir -p ~/Box/screen
xdg-mime default thunar.desktop inode/directory
LANG=en_US.UTF-8 xdg-user-dirs-update --force
