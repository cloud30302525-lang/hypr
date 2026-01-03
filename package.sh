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
	file-roller
	thunar-archive-plugin
	gvfs
	tumbler
	geany # == files == #
	feh
	clapper
)

paru -S --needed --noconfirm "${PKGS[@]}"
