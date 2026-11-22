#!/bin/sh
# Install the complete NEXORA XFCE desktop on Debian 13 Minimal or Terminal systems.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

ACTION="${1:-install}"

usage() {
    cat <<'EOF'
NEXORA Desktop — Debian 13 (Trixie)

Usage:
  sudo ./scripts/install-nexora-desktop.sh install
  sudo nexora-desktop status
  sudo nexora-desktop help

The installer adds the NEXORA XFCE desktop to an existing Debian 13 system.
It does not reinstall Debian or remove existing desktop environments.
EOF
}

if [ "$ACTION" = "help" ] || [ "$ACTION" = "--help" ] || [ "$ACTION" = "-h" ]; then
    usage
    exit 0
fi

if [ "$ACTION" = "status" ]; then
    if command -v xfce4-session >/dev/null 2>&1 && command -v lightdm >/dev/null 2>&1; then
        echo "NEXORA Desktop components detected (XFCE + LightDM)."
        [ -s /etc/nexora-release ] && cat /etc/nexora-release || true
        exit 0
    fi
    echo "NEXORA Desktop is not fully installed."
    exit 1
fi

if [ "$ACTION" != "install" ]; then
    echo "Unknown action: $ACTION" >&2
    usage >&2
    exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with: sudo $0 install" >&2
    exit 1
fi

if [ ! -r /etc/debian_version ] || ! grep -q '^13\.' /etc/debian_version; then
    echo "This installer currently targets Debian 13 (Trixie)." >&2
    exit 1
fi

need_file() {
    [ -s "$1" ] || { echo "Missing project file: $1" >&2; exit 1; }
}

for f in \
    config/includes.chroot/etc/nexora-release \
    config/includes.chroot/usr/share/backgrounds/nexora/nexora-default.svg \
    config/includes.chroot/usr/share/pixmaps/nexora-icon.svg \
    config/includes.chroot/usr/share/themes/NEXORA/gtk-3.0/gtk.css \
    config/includes.chroot/usr/share/nexora/fastfetch/nexora.txt \
    config/includes.chroot/etc/skel/.config/fastfetch/config.jsonc \
    config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
    config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml \
    config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml \
    config/includes.chroot/usr/bin/nexora-welcome \
    config/includes.chroot/usr/bin/nexora-store \
    config/includes.chroot/usr/share/applications/nexora-welcome.desktop \
    config/includes.chroot/usr/share/applications/nexora-store.desktop \
    config/includes.chroot/usr/share/nexora-store/catalog.json \
    config/includes.chroot/usr/share/nexora-store/store.css \
    config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf
do
    need_file "$f"
done

echo "==> Refreshing Debian package indexes..."
apt-get update

echo "==> Installing the lightweight XFCE desktop and NEXORA runtime dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xserver-xorg xfce4-session xfce4-panel xfdesktop4 xfwm4 xfconf \
    xfce4-settings xfce4-appfinder xfce4-terminal xfce4-whiskermenu-plugin \
    thunar thunar-volman gvfs dbus-x11 \
    lightdm lightdm-gtk-greeter adwaita-icon-theme \
    network-manager network-manager-gnome udisks2 upower polkitd pkexec lxpolkit \
    pipewire-audio pipewire-pulse wireplumber xfce4-pulseaudio-plugin \
    flatpak python3-gi gir1.2-gtk-3.0 xdg-desktop-portal xdg-desktop-portal-gtk \
    fastfetch desktop-file-utils locales ca-certificates curl wget

echo "==> Installing NEXORA branding and applications..."
install -D -m 0644 config/includes.chroot/etc/nexora-release /etc/nexora-release
install -D -m 0644 config/includes.chroot/usr/share/backgrounds/nexora/nexora-default.svg /usr/share/backgrounds/nexora/nexora-default.svg
install -D -m 0644 config/includes.chroot/usr/share/pixmaps/nexora-icon.svg /usr/share/pixmaps/nexora-icon.svg
install -D -m 0644 config/includes.chroot/usr/share/themes/NEXORA/gtk-3.0/gtk.css /usr/share/themes/NEXORA/gtk-3.0/gtk.css
install -D -m 0644 config/includes.chroot/usr/share/nexora/fastfetch/nexora.txt /usr/share/nexora/fastfetch/nexora.txt
install -D -m 0644 config/includes.chroot/usr/share/nexora-store/catalog.json /usr/share/nexora-store/catalog.json
install -D -m 0644 config/includes.chroot/usr/share/nexora-store/store.css /usr/share/nexora-store/store.css
install -D -m 0755 config/includes.chroot/usr/bin/nexora-welcome /usr/bin/nexora-welcome
install -D -m 0755 config/includes.chroot/usr/bin/nexora-store /usr/bin/nexora-store
install -D -m 0644 config/includes.chroot/usr/share/applications/nexora-welcome.desktop /usr/share/applications/nexora-welcome.desktop
install -D -m 0644 config/includes.chroot/usr/share/applications/nexora-store.desktop /usr/share/applications/nexora-store.desktop
install -D -m 0644 config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf

SKEL="$ROOT_DIR/config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
SYSTEM="/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
NEW_USER_DEFAULTS="/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"

# Configure system-wide defaults and defaults for future user accounts.
for destination in "$SYSTEM" "$NEW_USER_DEFAULTS"; do
    install -d -m 0755 "$destination"
    for file in xfce4-desktop.xml xfce4-panel.xml xsettings.xml; do
        install -m 0644 "$SKEL/$file" "$destination/$file"
    done
done
install -D -m 0644 config/includes.chroot/etc/skel/.config/fastfetch/config.jsonc /etc/skel/.config/fastfetch/config.jsonc

# Set NEXORA as the GTK3 default theme.
install -d -m 0755 /etc/gtk-3.0
cat > /etc/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=NEXORA
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-enable-animations=true
EOF

# Apply NEXORA defaults to the account that invoked sudo, preserving backups.
TARGET_USER="${SUDO_USER:-}"
if [ -n "$TARGET_USER" ] && id "$TARGET_USER" >/dev/null 2>&1 && [ "$TARGET_USER" != root ]; then
    HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    if [ -n "$HOME_DIR" ] && [ -d "$HOME_DIR" ]; then
        USER_CONFIG="$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
        USER_GROUP=$(id -gn "$TARGET_USER")
        install -d -o "$TARGET_USER" -g "$USER_GROUP" "$USER_CONFIG"
        for file in xfce4-desktop.xml xfce4-panel.xml xsettings.xml; do
            if [ -e "$USER_CONFIG/$file" ] && [ ! -e "$USER_CONFIG/$file.nexora-backup" ]; then
                cp -a "$USER_CONFIG/$file" "$USER_CONFIG/$file.nexora-backup"
            fi
            install -m 0644 "$SKEL/$file" "$USER_CONFIG/$file"
        done
        install -D -m 0644 config/includes.chroot/etc/skel/.config/fastfetch/config.jsonc "$HOME_DIR/.config/fastfetch/config.jsonc"
        chown -R "$TARGET_USER:$USER_GROUP" "$HOME_DIR/.config/xfce4" "$HOME_DIR/.config/fastfetch"
    fi
fi

# Enable networking and graphical login without removing another installed desktop.
systemctl enable NetworkManager.service >/dev/null 2>&1 || true
if [ -x /usr/sbin/lightdm ]; then
    printf '%s\n' /usr/sbin/lightdm > /etc/X11/default-display-manager
    systemctl enable lightdm.service
fi
systemctl set-default graphical.target

if ! flatpak remote-list --system --columns=name 2>/dev/null | grep -qx flathub; then
    flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
install -d -m 0755 /usr/local/sbin
ln -sf "$ROOT_DIR/scripts/install-nexora-desktop.sh" /usr/local/sbin/nexora-desktop

echo
echo "NEXORA Desktop installation completed."
echo "Restart the computer to start the graphical login:"
echo "  sudo reboot"
echo
echo "After installation, use:"
echo "  nexora-desktop status"
echo "Note: this adds the NEXORA XFCE desktop to Debian 13; it does not replace Debian's base system."
