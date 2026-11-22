#!/usr/bin/env bash
# Build the main NEXORA XFCE4 edition as a bootable Debian Live hybrid ISO.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-output"
WORK_DIR="$OUTPUT_DIR/live-build"
OUTPUT_ISO="$OUTPUT_DIR/nexora-os-xfce4-live-amd64.iso"

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script as root: sudo ./scripts/build-live.sh" >&2
    exit 1
fi

for command in lb xorriso sha256sum; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command is missing: $command" >&2
        exit 1
    fi
done

mkdir -p "$OUTPUT_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/config"

# Start from the repository's existing NEXORA system defaults.
cp -a "$ROOT_DIR/config/." "$WORK_DIR/config/"
mkdir -p "$WORK_DIR/config/includes.chroot"
mkdir -p "$WORK_DIR/config/package-lists"

# Merge the complete NEXORA desktop overlay into the live root filesystem.
cp -a "$ROOT_DIR/installer/desktop-overlay/." "$WORK_DIR/config/includes.chroot/"
cp "$ROOT_DIR/config/package-lists/nexora-live.list.chroot" \
    "$WORK_DIR/config/package-lists/nexora-live.list.chroot"

# Ensure application entry points are executable in the resulting live system.
chmod 0755 "$WORK_DIR/config/includes.chroot"/usr/bin/nexora-* \
    "$WORK_DIR/config/includes.chroot/usr/local/sbin/nexora-postinstall"

# Identify the live edition clearly from the running system.
cat > "$WORK_DIR/config/includes.chroot/etc/nexora-release" <<'RELEASE'
NEXORA OS XFCE4 Live 0.1.0-alpha.2
Base: Debian GNU/Linux 13 (Trixie)
Desktop: XFCE4
Boot mode: Live hybrid ISO
Installer: Debian Installer Live
Architecture: amd64
Tagline: Your Terminal. Your Universe.
RELEASE

mkdir -p "$WORK_DIR/config/includes.chroot/etc/skel/Desktop"
cp "$WORK_DIR/config/includes.chroot/usr/share/applications/nexora-installer.desktop" \
   "$WORK_DIR/config/includes.chroot/etc/skel/Desktop/Install-NEXORA.desktop"
chmod 0755 "$WORK_DIR/config/includes.chroot/etc/skel/Desktop/Install-NEXORA.desktop"

cd "$WORK_DIR"

echo "==> Configuring Debian Live for NEXORA XFCE4..."
lb config \
    --distribution trixie \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --debian-installer live \
    --debian-installer-gui true \
    --archive-areas "main contrib non-free non-free-firmware" \
    --bootappend-live "boot=live components locales=es_CL.UTF-8 keyboard-layouts=latam username=nexora" \
    --apt-recommends true \
    --iso-application "NEXORA OS XFCE4 Live" \
    --iso-publisher "NEXORA Project" \
    --iso-volume "NEXORA_XFCE4_LIVE"

echo "==> Building the complete XFCE4 live filesystem and installer..."
lb build

BUILT_ISO="$WORK_DIR/live-image-amd64.hybrid.iso"
if [[ ! -s "$BUILT_ISO" ]]; then
    BUILT_ISO="$WORK_DIR/live-image-amd64.iso"
fi
if [[ ! -s "$BUILT_ISO" ]]; then
    echo "live-build did not produce the expected hybrid ISO." >&2
    find "$WORK_DIR" -maxdepth 2 -type f -name '*.iso' -print >&2
    exit 1
fi

cp "$BUILT_ISO" "$OUTPUT_ISO"

echo "==> Checking the Live filesystem and installer media..."
LIVE_CONTENTS="$(xorriso -indev "$OUTPUT_ISO" -ls /live 2>&1 || true)"
printf '%s\n' "$LIVE_CONTENTS"
printf '%s\n' "$LIVE_CONTENTS" | grep -q 'filesystem.squashfs' || {
    echo "The ISO does not contain the compressed live root filesystem." >&2
    exit 1
}
printf '%s\n' "$LIVE_CONTENTS" | grep -Eq 'vmlinuz|linux' || {
    echo "The live kernel is missing from the ISO." >&2
    exit 1
}
BOOT_REPORT="$(xorriso -indev "$OUTPUT_ISO" -report_el_torito plain 2>&1 || true)"
printf '%s\n' "$BOOT_REPORT"
printf '%s\n' "$BOOT_REPORT" | grep -qi 'El Torito' || {
    echo "The ISO has no El Torito boot catalog." >&2
    exit 1
}

SIZE_HUMAN="$(du -h "$OUTPUT_ISO" | awk '{print $1}')"
SHA256="$(sha256sum "$OUTPUT_ISO" | awk '{print $1}')"
printf '%s  %s\n' "$SHA256" "$(basename "$OUTPUT_ISO")" > "$OUTPUT_ISO.sha256"

echo
echo "==> NEXORA OS XFCE4 Live ISO created:"
echo "    $OUTPUT_ISO"
echo "    Size: $SIZE_HUMAN"
echo "    SHA256: $SHA256"
echo "    Live desktop: XFCE4"
echo "    Desktop installer: debian-installer-launcher live"
echo "    Base: Debian 13 Trixie"
