#!/bin/sh
# Build the NEXORA OS Minimal netinst prototype using Debian Installer GTK.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo ./scripts/build.sh" >&2
    exit 1
fi

for command in curl xorriso; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command is missing: $command" >&2
        exit 1
    fi
done

VERSION="${NEXORA_DEBIAN_VERSION:-trixie}"
ARCH="${NEXORA_ARCH:-amd64}"
BASE_URL="https://deb.debian.org/debian/dists/${VERSION}/main/installer-${ARCH}/current/images/netboot/gtk"
SOURCE_ISO="$ROOT_DIR/build-output/debian-installer-${VERSION}-${ARCH}-gtk-mini.iso"
OUTPUT_ISO="$ROOT_DIR/build-output/nexora-os-minimal-netinst-${ARCH}.iso"

mkdir -p "$ROOT_DIR/build-output"
rm -f "$SOURCE_ISO" "$OUTPUT_ISO"

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

echo "==> Embedding NEXORA installer profiles and preserving boot records..."
xorriso -indev "$SOURCE_ISO" \
    -outdev "$OUTPUT_ISO" \
    -volid "NEXORA_MINIMAL" \
    -map "$ROOT_DIR/installer/preseed" /nexora/preseed \
    -map "$ROOT_DIR/installer/desktop-overlay" /nexora/desktop-overlay \
    -map "$ROOT_DIR/installer/BOOT-OPTIONS.md" /nexora/BOOT-OPTIONS.md \
    -boot_image any replay \
    -commit \
    -end

echo "==> Verifying embedded NEXORA profiles and El Torito boot metadata..."
xorriso -indev "$OUTPUT_ISO" -toc >/dev/null
profile_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/preseed 2>&1)
printf '%s\\n' "$profile_listing"
printf '%s\\n' "$profile_listing" | grep -q 'minimal.cfg' || {
    echo "Minimal preseed profile is missing from the ISO." >&2
    exit 1
}
printf '%s\\n' "$profile_listing" | grep -q 'desktop.cfg' || {
    echo "XFCE preseed profile is missing from the ISO." >&2
    exit 1
}
overlay_listing=$(xorriso -indev "$OUTPUT_ISO" -ls /nexora/desktop-overlay/usr/share/backgrounds/nexora 2>&1)
printf '%s\\n' "$overlay_listing"
printf '%s\\n' "$overlay_listing" | grep -q 'nexora-aurora.svg' || {
    echo "NEXORA desktop overlay is missing its wallpapers." >&2
    exit 1
}
boot_report=$(xorriso -indev "$OUTPUT_ISO" -report_el_torito plain 2>&1)
printf '%s\n' "$boot_report"
printf '%s\n' "$boot_report" | grep -qi 'El Torito' || {
    echo "No El Torito boot catalog was found in the resulting ISO." >&2
    exit 1
}

size_human=$(du -h "$OUTPUT_ISO" | awk '{print $1}')
sha256=$(sha256sum "$OUTPUT_ISO" | awk '{print $1}')

echo
echo "==> NEXORA OS Minimal GTK netinst prototype created:"
echo "    $OUTPUT_ISO"
echo "    ISO size: $size_human"
echo "    SHA256: $sha256"
echo
echo "Profiles embedded:"
echo "    /nexora/preseed/minimal.cfg"
echo "    /nexora/preseed/desktop.cfg"
echo "Use the boot arguments documented in /nexora/BOOT-OPTIONS.md."
echo "NOTE: The graphical installer still uses Debian's upstream GTK interface."
