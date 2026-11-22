#!/bin/sh
# Install the NEXORA XFCE desktop on an existing NEXORA OS Minimal / Debian 13 system.
set -eu

SCRIPT_PATH=$(readlink -f "$0")
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_PATH")/.." && pwd)
OVERLAY="$ROOT_DIR/installer/desktop-overlay"
ACTION="${1:-install}"

usage() {
    cat <<'EOF'
NEXORA Desktop installer — Debian 13 (Trixie)

Usage:
  sudo sh ./scripts/install-nexora-desktop.sh install
  nexora-desktop status
  nexora-desktop help

Actions:
  install   Install XFCE4, LightDM and the NEXORA desktop components.
  status    Check whether the NEXORA desktop is installed.
  help      Show this help.

The installer does not repartition disks or reinstall Debian.
EOF
}

desktop_status() {
    if [ -x /usr/bin/xfce4-session ] &&
       [ -x /usr/sbin/lightdm ] &&
       [ -s /etc/nexora-release ] &&
       grep -q 'Desktop: XFCE' /etc/nexora-release; then
        echo "NEXORA Desktop is installed."
        cat /etc/nexora-release
        return 0
    fi
    echo "NEXORA Desktop is not fully installed."
    return 1
}

case "$ACTION" in
    help|--help|-h) usage; exit 0 ;;
    status) desktop_status; exit $? ;;
    install) ;;
    *)
        echo "Unknown action: $ACTION" >&2
        usage >&2
        exit 2
        ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with: sudo $0 install" >&2
    exit 1
fi

if [ ! -r /etc/debian_version ] || ! grep -q '^13\.' /etc/debian_version; then
    echo "This installer supports Debian 13 (Trixie) only." >&2
    exit 1
fi

for file in \
    "$OVERLAY/usr/local/sbin/nexora-postinstall" \
    "$OVERLAY/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
    "$OVERLAY/usr/bin/nexora-store" \
    "$OVERLAY/usr/share/nexora/catalog.json" \
    "$OVERLAY/usr/share/backgrounds/nexora/nexora-default.svg" \
    "$OVERLAY/usr/share/backgrounds/nexora/nexora-aurora.svg" \
    "$OVERLAY/usr/share/backgrounds/nexora/nexora-orbit.svg" \
    "$OVERLAY/usr/share/backgrounds/nexora/nexora-grid.svg" \
    "$OVERLAY/usr/share/backgrounds/nexora/nexora-midnight.svg" \
    "$ROOT_DIR/config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf"
do
    [ -s "$file" ] || { echo "Required NEXORA desktop file is missing: $file" >&2; exit 1; }
done

echo "==> Refreshing Debian package indexes..."
apt-get update

echo "==> Installing the Debian XFCE desktop and NEXORA runtime dependencies..."
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    task-xfce-desktop lightdm lightdm-gtk-greeter network-manager network-manager-gnome \
    dbus-x11 sudo flatpak python3-gi gir1.2-gtk-3.0 policykit-1 lxpolkit \
    xfce4-taskmanager xfce4-goodies xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin \
    desktop-file-utils xdg-utils fonts-noto fonts-noto-color-emoji \
    gvfs gvfs-backends tumbler firefox-esr gparted

# Preserve existing per-user XFCE settings before the NEXORA defaults are applied.
for home in /home/*; do
    [ -d "$home" ] || continue
    config="$home/.config/xfce4/xfconf/xfce-perchannel-xml"
    [ -d "$config" ] || continue
    for file in xfce4-panel.xml xfce4-desktop.xml xsettings.xml; do
        if [ -s "$config/$file" ] && [ ! -e "$config/$file.nexora-backup" ]; then
            cp -a "$config/$file" "$config/$file.nexora-backup"
        fi
    done
done

echo "==> Applying NEXORA desktop files and branding..."
cp -a "$OVERLAY/." /
install -D -m 0644 "$ROOT_DIR/config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf

echo "==> Applying NEXORA desktop defaults..."
/bin/sh /usr/local/sbin/nexora-postinstall

PANEL_CONFIG="/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml"
SYSTEM_CONFIG="/etc/xdg/xfce4/xfconf/xfce-perchannel-xml"
install -d -m 0755 "$SYSTEM_CONFIG"
for file in xfce4-panel.xml xfce4-desktop.xml xsettings.xml; do
    if [ -s "$PANEL_CONFIG/$file" ]; then
        install -m 0644 "$PANEL_CONFIG/$file" "$SYSTEM_CONFIG/$file"
    fi
done

# Ensure the two-panel NEXORA layout is present for the account running sudo.
TARGET_USER="${SUDO_USER:-}"
if [ -n "$TARGET_USER" ] && id "$TARGET_USER" >/dev/null 2>&1 && [ "$TARGET_USER" != root ]; then
    HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    if [ -n "$HOME_DIR" ] && [ -d "$HOME_DIR" ]; then
        USER_CONFIG="$HOME_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
        install -d -m 0755 "$USER_CONFIG"
        for file in xfce4-panel.xml xfce4-desktop.xml xsettings.xml; do
            [ -s "$PANEL_CONFIG/$file" ] && install -m 0644 "$PANEL_CONFIG/$file" "$USER_CONFIG/$file"
        done
        chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$HOME_DIR/.config/xfce4"
    fi
fi

# Enable networking and graphical login; do not touch partition tables or user data.
systemctl enable NetworkManager.service >/dev/null 2>&1 || true
install -d -m 0755 /etc/X11
printf '%s\n' /usr/sbin/lightdm > /etc/X11/default-display-manager
systemctl enable lightdm.service
systemctl set-default graphical.target

# Install a small status/help command that remains usable after the source checkout is removed.
chmod 0755 "$SCRIPT_PATH"
install -d -m 0755 /usr/local/bin
cat > /usr/local/bin/nexora-desktop <<EOF
#!/bin/sh
SOURCE_INSTALLER='$SCRIPT_PATH'
case "\${1:-status}" in
    status)
        if [ -x /usr/bin/xfce4-session ] && [ -x /usr/sbin/lightdm ] && [ -s /etc/nexora-release ] && grep -q 'Desktop: XFCE' /etc/nexora-release; then
            echo "NEXORA Desktop is installed."
            cat /etc/nexora-release
            exit 0
        fi
        echo "NEXORA Desktop is not fully installed."
        exit 1
        ;;
    help|--help|-h)
        echo "Usage: nexora-desktop {status|help|install}"
        ;;
    install)
        if [ -x "\$SOURCE_INSTALLER" ]; then
            exec "\$SOURCE_INSTALLER" install
        fi
        echo "Reinstall from the NEXORA-OS source checkout: sudo ./scripts/install-nexora-desktop.sh install" >&2
        exit 1
        ;;
    *)
        echo "Usage: nexora-desktop {status|help|install}" >&2
        exit 2
        ;;
esac
EOF
chmod 0755 /usr/local/bin/nexora-desktop

echo
echo "NEXORA Desktop installation completed."
echo "The next boot will start the graphical login."
echo "Run: sudo reboot"
echo "Check later with: nexora-desktop status"
echo "Your existing Debian installation and disk partitions were not changed."
