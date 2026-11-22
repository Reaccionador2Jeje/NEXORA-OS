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

echo "==> Embedding NEXORA installer profiles and preserving boot records..."
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
    -map "$BOOT_BRANDING_DIR/menu.cfg" "$SYSLINUX_MENU_PATH" \
    -map "$INITRD_BRANDING_DIR/initrd-nexora.gz" /initrd.gz \
    -boot_image any replay \
    -commit \
    -end

echo "==> Verifying embedded NEXORA profiles and El Torito boot metadata..."
# El Torito is verified explicitly below. Avoid -toc here because xorriso may
# return status 5 after successfully reading an otherwise valid ISO.
profile_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/preseed 2>&1 || true)
printf '%s\n' "$profile_listing"
printf '%s\n' "$profile_listing" | grep -q 'minimal.cfg' || {
    echo "Minimal preseed profile is missing from the ISO." >&2
    exit 1
}
printf '%s\n' "$profile_listing" | grep -q 'desktop.cfg' || {
    echo "XFCE preseed profile is missing from the ISO." >&2
    exit 1
}
branding_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora 2>&1 || true)
printf '%s\n' "$branding_listing" | grep -q 'nexora-installer-background.png' || {
    echo "NEXORA installer background is missing from the ISO." >&2
    exit 1
}
MENU_VERIFY_DIR="$ROOT_DIR/build-output/menu-verification"
rm -rf "$MENU_VERIFY_DIR"
mkdir -p "$MENU_VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /boot/grub/grub.cfg "$MENU_VERIFY_DIR/grub.cfg" \
    -extract "$SYSLINUX_MENU_PATH" "$MENU_VERIFY_DIR/menu.cfg" \
    >/dev/null 2>&1
grep -q "NEXORA OS Minimal" "$MENU_VERIFY_DIR/grub.cfg" || {
    echo "UEFI NEXORA Minimal boot entry is missing from the embedded GRUB menu." >&2
    exit 1
}
grep -q "NEXORA OS XFCE Desktop" "$MENU_VERIFY_DIR/grub.cfg" || {
    echo "UEFI NEXORA XFCE boot entry is missing from the embedded GRUB menu." >&2
    exit 1
}
grep -q "NEXORA OS Minimal" "$MENU_VERIFY_DIR/menu.cfg" || {
    echo "BIOS NEXORA Minimal boot entry is missing from the embedded Syslinux menu." >&2
    exit 1
}
grep -q "NEXORA OS XFCE Desktop" "$MENU_VERIFY_DIR/menu.cfg" || {
    echo "BIOS NEXORA XFCE boot entry is missing from the embedded Syslinux menu." >&2
    exit 1
}
installer_branding=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/branding 2>&1 || true)
printf '%s\n' "$installer_branding" | grep -q 'nexora-installer.svg' || {
    echo "NEXORA installer SVG branding is missing from the ISO." >&2
    exit 1
}
overlay_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/desktop-overlay/usr/share/backgrounds/nexora 2>&1 || true)
printf '%s\n' "$overlay_listing"
printf '%s\n' "$overlay_listing" | grep -q 'nexora-aurora.svg' || {
    echo "NEXORA desktop overlay is missing its wallpapers." >&2
    exit 1
}
boot_report=$(xorriso -indev "$OUTPUT_ISO" -report_el_torito plain 2>&1 || true)
printf '%s\n' "$boot_report"
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
echo "Profiles embedded:"
echo "    /nexora/preseed/minimal.cfg"
echo "    /nexora/preseed/desktop.cfg"
echo "Boot menu: NEXORA Minimal / NEXORA XFCE, with upstream fallback entries. Default: $EDITION."
echo "GTK banner: NEXORA logos embedded in both light and dark installer variants."
echo "GTK controls and workflow remain Debian Installer components."
