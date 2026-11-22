#!/bin/sh
# Apply NEXORA OS desktop components to an existing Debian 13 XFCE installation.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with: sudo ./scripts/install-nexora-desktop.sh" >&2
    exit 1
fi

if [ ! -r /etc/debian_version ] || ! grep -q '^13\.' /etc/debian_version; then
    echo "This installer currently targets Debian 13 (Trixie)." >&2
    exit 1
fi

if ! command -v xfce4-session >/dev/null 2>&1; then
    echo "XFCE is not installed. This script applies the NEXORA XFCE edition only." >&2
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
    config/includes.chroot/usr/share/nexora-store/store.css
do
    need_file "$f"
done

echo "==> Installing NEXORA runtime dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    fastfetch flatpak python3-gi gir1.2-gtk-3.0 \
    xfce4-whiskermenu-plugin adwaita-icon-theme desktop-file-utils

echo "==> Installing NEXORA branding and applications..."
install -D -m 0644 config/includes.chroot/etc/nexora-release /etc/nexora-release
install -D -m 0644 config/includes.chroot/usr/share/backgrounds/nexora/nexora-default.svg /usr/share/backgrounds/nexora/nexora-default.svg
install -D -m 0644 config/includes.chroot/usr/share/pixmaps/nexora-icon.svg /usr/share/pixmaps/nexora-icon.svg
install -D -m 0644 config/includes.chroot/usr/share/themes/NEXORA/gtk-3.0/gtk.css /usr/share/themes/NEXORA/gtk-3.0/gtk.css
install -D -m 0644 config/includes.chroot/usr/share/nexora/fastfetch/nexora.txt /usr/share/nexora/fastfetch/nexora.txt
    config/includes.chroot/usr/share/nexora-store/catalog.json \
install -D -m 0644 config/includes.chroot/usr/share/nexora-store/store.css /usr/share/nexora-store/store.css
install -D -m 0755 config/includes.chroot/usr/bin/nexora-welcome /usr/bin/nexora-welcome
install -D -m 0755 config/includes.chroot/usr/bin/nexora-store /usr/bin/nexora-store
install -D -m 0644 config/includes.chroot/usr/share/applications/nexora-welcome.desktop /usr/share/applications/nexora-welcome.desktop
install -D -m 0644 config/includes.chroot/usr/share/applications/nexora-store.desktop /usr/share/applications/nexora-store.desktop

SKEL="$ROOT_DIR/config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
SYSTEM="/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
install -D -m 0644 "$SKEL/xfce4-desktop.xml" "$SYSTEM/xfce4-desktop.xml"
install -D -m 0644 "$SKEL/xfce4-panel.xml" "$SYSTEM/xfce4-panel.xml"
install -D -m 0644 "$SKEL/xsettings.xml" "$SYSTEM/xsettings.xml"
install -D -m 0644 config/includes.chroot/etc/skel/.config/fastfetch/config.jsonc /etc/skel/.config/fastfetch/config.jsonc

install -d -m 0755 /etc/gtk-3.0
cat > /etc/gtk-3.0/settings.ini <<'EOF'
[Settings]
gtk-theme-name=NEXORA
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-enable-animations=true
EOF

if ! flatpak remote-list --system --columns=name 2>/dev/null | grep -qx flathub; then
    flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

TARGET_USER="${SUDO_USER:-}"
if [ -n "$TARGET_USER" ] && id "$TARGET_USER" >/dev/null 2>&1 && [ "$TARGET_USER" != root ]; then
    HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    if [ -n "$HOME_DIR" ] && [ -d "$HOME_DIR" ]; then
        USER_CONFIG="$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
        install -d -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$USER_CONFIG"
        for f in xfce4-desktop.xml xfce4-panel.xml xsettings.xml; do
            if [ -e "$USER_CONFIG/$f" ]; then
                cp -n "$USER_CONFIG/$f" "$USER_CONFIG/$f.nexora-backup" || true
            fi
            install -m 0644 "$SKEL/$f" "$USER_CONFIG/$f"
        done
        install -D -m 0644 config/includes.chroot/etc/skel/.config/fastfetch/config.jsonc "$HOME_DIR/.config/fastfetch/config.jsonc"
        chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$HOME_DIR/.config/xfce4" "$HOME_DIR/.config/fastfetch"
    fi
fi

update-desktop-database /usr/share/applications >/dev/null 2>&1 || true

echo
echo "NEXORA desktop components installed."
echo "Log out and back in to reload XFCE settings."
echo "Run 'fastfetch' to check the NEXORA system identity."
echo "Note: this does not convert Debian into a fully released NEXORA distribution or install the NEXORA Plymouth boot theme."
