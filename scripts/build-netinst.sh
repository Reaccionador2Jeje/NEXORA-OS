#!/bin/sh
# Build a NEXORA OS Minimal or XFCE4 netinst image using Debian Installer GTK.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo ./scripts/build.sh" >&2
    exit 1
fi

for command in curl xorriso cpio gzip python3; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command is missing: $command" >&2
        exit 1
    fi
done

VERSION="${NEXORA_DEBIAN_VERSION:-trixie}"
ARCH="${NEXORA_ARCH:-amd64}"
EDITION="${NEXORA_EDITION:-minimal}"
case "$EDITION" in
    minimal) ISO_EDITION="minimal"; ISO_VOLUME="NEXORA_MINIMAL" ;;
    xfce) ISO_EDITION="xfce4"; ISO_VOLUME="NEXORA_XFCE" ;;
    *) echo "Unsupported NEXORA_EDITION: $EDITION (use minimal or xfce)" >&2; exit 2 ;;
esac
BASE_URL="https://deb.debian.org/debian/dists/${VERSION}/main/installer-${ARCH}/current/images/netboot/gtk"
SOURCE_ISO="$ROOT_DIR/build-output/debian-installer-${VERSION}-${ARCH}-gtk-mini.iso"
OUTPUT_ISO="$ROOT_DIR/build-output/nexora-os-${ISO_EDITION}-netinst-${ARCH}.iso"

mkdir -p "$ROOT_DIR/build-output"
rm -f "$SOURCE_ISO" "$OUTPUT_ISO"
python3 "$ROOT_DIR/scripts/create-installer-background.py" "$ROOT_DIR/build-output/nexora-installer-background.png"
GTK_LOGO_DIR="$ROOT_DIR/build-output/gtk-logos"
mkdir -p "$GTK_LOGO_DIR"
python3 "$ROOT_DIR/scripts/create-installer-logo.py" \
    "$GTK_LOGO_DIR/nexora-logo-light.png" \
    "$GTK_LOGO_DIR/nexora-logo-dark.png"

echo "==> Downloading the official Debian ${VERSION} GTK netboot mini ISO..."
curl --fail --location --retry 4 --retry-delay 3 \
    --output "$SOURCE_ISO" \
    "$BASE_URL/mini.iso"

if [ ! -s "$SOURCE_ISO" ]; then
    echo "The Debian GTK mini ISO download is empty." >&2
    exit 1
fi

size_bytes=$(wc -c < "$SOURCE_ISO" | tr -d ' ')
if [ "$size_bytes" -lt 40000000 ]; then
    echo "Downloaded image is unexpectedly small; refusing to package it." >&2
    exit 1
fi

echo "==> Rebranding the GTK installer banner inside initrd..."
INITRD_BRANDING_DIR="$ROOT_DIR/build-output/initrd-branding"
rm -rf "$INITRD_BRANDING_DIR"
python3 "$ROOT_DIR/scripts/brand-installer-initrd.py" \
    "$SOURCE_ISO" "$INITRD_BRANDING_DIR" \
    "$GTK_LOGO_DIR/nexora-logo-light.png" \
    "$GTK_LOGO_DIR/nexora-logo-dark.png"

echo "==> Preparing NEXORA BIOS and UEFI boot menus..."
BOOT_BRANDING_DIR="$ROOT_DIR/build-output/boot-branding"
rm -rf "$BOOT_BRANDING_DIR"
NEXORA_DEFAULT_PROFILE="$EDITION" python3 "$ROOT_DIR/scripts/brand-installer-boot.py" "$SOURCE_ISO" "$BOOT_BRANDING_DIR"
SYSLINUX_MENU_PATH=$(cat "$BOOT_BRANDING_DIR/menu-path.txt")
ISOLINUX_CONFIG_PATH=$(cat "$BOOT_BRANDING_DIR/isolinux-path.txt")

echo "==> Embedding NEXORA artwork, profiles and boot menus..."
xorriso -indev "$SOURCE_ISO" \
    -outdev "$OUTPUT_ISO" \
    -volid "$ISO_VOLUME" \
    -map "$ROOT_DIR/installer/preseed" /nexora/preseed \
    -map "$ROOT_DIR/installer/desktop-overlay" /nexora/desktop-overlay \
    -map "$ROOT_DIR/installer/BOOT-OPTIONS.md" /nexora/BOOT-OPTIONS.md \
    -map "$ROOT_DIR/installer/branding" /nexora/branding \
    -map "$ROOT_DIR/build-output/nexora-installer-background.png" /nexora/nexora-installer-background.png \
    -map "$ROOT_DIR/build-output/nexora-installer-background.png" /isolinux/splash.png \
    -map "$ROOT_DIR/build-output/nexora-installer-background.png" /boot/grub/splash.png \
    -map "$BOOT_BRANDING_DIR/grub.cfg" /boot/grub/grub.cfg \
    -map "$BOOT_BRANDING_DIR/isolinux.cfg" "$ISOLINUX_CONFIG_PATH" \
    -map "$BOOT_BRANDING_DIR/menu.cfg" "$SYSLINUX_MENU_PATH" \
    -map "$INITRD_BRANDING_DIR/initrd-nexora.gz" /initrd.gz \
    -boot_image any replay \
    -commit \
    -end

echo "==> Verifying NEXORA background is connected to both boot menus..."
branding_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora 2>&1 || true)
printf '%s\n' "$branding_listing" | grep -q 'nexora-installer-background.png' || {
    echo "NEXORA installer background is missing from the ISO." >&2
    exit 1
}
BOOT_SPLASH_VERIFY_DIR="$ROOT_DIR/build-output/boot-splash-verification"
rm -rf "$BOOT_SPLASH_VERIFY_DIR"
mkdir -p "$BOOT_SPLASH_VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /nexora/nexora-installer-background.png "$BOOT_SPLASH_VERIFY_DIR/nexora-background.png" \
    -extract /isolinux/splash.png "$BOOT_SPLASH_VERIFY_DIR/isolinux-splash.png" \
    -extract /boot/grub/splash.png "$BOOT_SPLASH_VERIFY_DIR/grub-splash.png" \
    >/dev/null 2>&1
cmp "$ROOT_DIR/build-output/nexora-installer-background.png" "$BOOT_SPLASH_VERIFY_DIR/nexora-background.png"
cmp "$ROOT_DIR/build-output/nexora-installer-background.png" "$BOOT_SPLASH_VERIFY_DIR/isolinux-splash.png"
cmp "$ROOT_DIR/build-output/nexora-installer-background.png" "$BOOT_SPLASH_VERIFY_DIR/grub-splash.png"

MENU_VERIFY_DIR="$ROOT_DIR/build-output/menu-verification"
rm -rf "$MENU_VERIFY_DIR"
mkdir -p "$MENU_VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /boot/grub/grub.cfg "$MENU_VERIFY_DIR/grub.cfg" \
    -extract "$ISOLINUX_CONFIG_PATH" "$MENU_VERIFY_DIR/isolinux.cfg" \
    -extract "$SYSLINUX_MENU_PATH" "$MENU_VERIFY_DIR/menu.cfg" \
    >/dev/null 2>&1
grep -q "NEXORA OS Minimal" "$MENU_VERIFY_DIR/grub.cfg" || {
    echo "UEFI NEXORA Minimal boot entry is missing." >&2
    exit 1
}
grep -q "NEXORA OS XFCE Desktop" "$MENU_VERIFY_DIR/grub.cfg" || {
    echo "UEFI NEXORA XFCE boot entry is missing." >&2
    exit 1
}
grep -q "background_image /nexora/nexora-installer-background.png" "$MENU_VERIFY_DIR/grub.cfg" || {
    echo "UEFI GRUB menu is not configured to use the NEXORA background." >&2
    exit 1
}
grep -q "menu_color_highlight=white/blue" "$MENU_VERIFY_DIR/grub.cfg" || {
    echo "UEFI GRUB menu is missing the NEXORA selection palette." >&2
    exit 1
}
grep -q "vesamenu.c32" "$MENU_VERIFY_DIR/isolinux.cfg" || {
    echo "BIOS menu is not using the graphics-capable vesamenu renderer." >&2
    exit 1
}
grep -q "menu background /nexora/nexora-installer-background.png" "$MENU_VERIFY_DIR/menu.cfg" || {
    echo "BIOS Syslinux menu is not configured to use the NEXORA background." >&2
    exit 1
}
grep -q "MENU COLOR sel" "$MENU_VERIFY_DIR/menu.cfg" || {
    echo "BIOS Syslinux menu is missing the NEXORA selection palette." >&2
    exit 1
}
grep -q "NEXORA OS Minimal" "$MENU_VERIFY_DIR/menu.cfg" || {
    echo "BIOS NEXORA Minimal boot entry is missing." >&2
    exit 1
}
grep -q "XFCE Desktop" "$MENU_VERIFY_DIR/menu.cfg" || {
    echo "BIOS NEXORA XFCE boot entry is missing." >&2
    exit 1
}

installer_branding=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/branding 2>&1 || true)
printf '%s\n' "$installer_branding" | grep -q 'nexora-installer.svg' || {
    echo "NEXORA installer SVG branding is missing from the ISO." >&2
    exit 1
}
overlay_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/desktop-overlay/usr/share/backgrounds/nexora 2>&1 || true)
printf '%s\n' "$overlay_listing" | grep -q 'nexora-aurora.svg' || {
    echo "NEXORA desktop overlay is missing its wallpapers." >&2
    exit 1
}

# Keep the native NEXORA installer payload available in the netinst ISO as well.
# Debian Installer remains the active netinst environment; the native GTK app
# runs from the XFCE4 Live session, where its copied-live-system engine operates.
NETINST_PAYLOAD_VERIFY="$ROOT_DIR/build-output/netinst-nexora-payload"
rm -rf "$NETINST_PAYLOAD_VERIFY"
mkdir -p "$NETINST_PAYLOAD_VERIFY"
for payload in \
    usr/bin/nexora-installer \
    usr/lib/nexora-installer/install-engine.py \
    usr/local/sbin/nexora-postinstall \
    usr/share/applications/nexora-installer.desktop \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
    usr/share/nexora/catalog.json usr/share/nexora/desktop-tools.json \
    usr/share/nexora/wallpapers.json
do
    xorriso -osirrox on -indev "$OUTPUT_ISO" \
        -extract "/nexora/desktop-overlay/$payload" "$NETINST_PAYLOAD_VERIFY/$(basename "$payload")" \
        >/dev/null 2>&1 || {
        echo "NEXORA installer payload is missing from netinst ISO: $payload" >&2
        exit 1
    }
    test -s "$NETINST_PAYLOAD_VERIFY/$(basename "$payload")" || {
        echo "NEXORA installer payload is empty in netinst ISO: $payload" >&2
        exit 1
    }
done
grep -q 'NEXORA OS.*installation wizard' "$NETINST_PAYLOAD_VERIFY/nexora-installer" || {
    echo "The bundled NEXORA GTK installer entry point is invalid." >&2
    exit 1
}
grep -q 'NEXORA OS disk installation engine' "$NETINST_PAYLOAD_VERIFY/install-engine.py" || {
    echo "The bundled NEXORA disk installation engine is invalid." >&2
    exit 1
}
for wallpaper in \
    nexora-default.svg nexora-aurora.svg nexora-nebula.svg nexora-horizon.svg \
    nexora-minimal.svg nexora-orbit.svg nexora-grid.svg nexora-midnight.svg
do
    xorriso -osirrox on -indev "$OUTPUT_ISO" \
        -extract "/nexora/desktop-overlay/usr/share/backgrounds/nexora/$wallpaper" \
        "$NETINST_PAYLOAD_VERIFY/$wallpaper" >/dev/null 2>&1 || {
        echo "NEXORA desktop wallpaper is missing from netinst payload: $wallpaper" >&2
        exit 1
    }
done
echo "NEXORA GTK installer payload, XFCE defaults and eight wallpapers verified in netinst ISO."
boot_report=$(xorriso -indev "$OUTPUT_ISO" -report_el_torito plain 2>&1 || true)
printf '%s\n' "$boot_report" | grep -qi 'El Torito' || {
    echo "No El Torito boot catalog was found in the resulting ISO." >&2
    exit 1
}

size_human=$(du -h "$OUTPUT_ISO" | awk '{print $1}')
sha256=$(sha256sum "$OUTPUT_ISO" | awk '{print $1}')

echo
echo "==> NEXORA OS $EDITION GTK netinst image created:"
echo "    $OUTPUT_ISO"
echo "    ISO size: $size_human"
echo "    SHA256: $sha256"
echo
echo "Boot menu: NEXORA background verified in UEFI GRUB and BIOS Syslinux."
echo "Installer profiles: Minimal and XFCE4; upstream Debian fallback entries preserved."
echo "GTK banner: NEXORA logos embedded in both light and dark installer variants."
echo "GTK controls and workflow remain Debian Installer components."
