#!/usr/bin/env bash
# Build the NEXORA XFCE4 Live edition with its native GTK installer.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-output"
WORK_DIR="$OUTPUT_DIR/live-build"
OUTPUT_ISO="$OUTPUT_DIR/nexora-os-xfce4-live-amd64.iso"

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script as root: sudo ./scripts/build-live.sh" >&2
    exit 1
fi

for command in lb xorriso sha256sum unsquashfs; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required command is missing: $command" >&2
        exit 1
    fi
done

# Debian Trixie's librsvg2-bin ships rsvg-convert, while live-build's
# legacy Syslinux helper invokes the older executable name "rsvg".
# Provide a compatible command shim on the host PATH for the binary stage.
if ! command -v rsvg >/dev/null 2>&1; then
    RSVG_CONVERT="$(command -v rsvg-convert || true)"
    if [[ -z "$RSVG_CONVERT" ]]; then
        echo "Required command is missing: rsvg-convert (package librsvg2-bin)" >&2
        exit 1
    fi
    RSVG_COMPAT_DIR="$OUTPUT_DIR/compat-bin"
    mkdir -p "$RSVG_COMPAT_DIR"
    ln -sfn "$RSVG_CONVERT" "$RSVG_COMPAT_DIR/rsvg"
    export PATH="$RSVG_COMPAT_DIR:$PATH"
fi

mkdir -p "$OUTPUT_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/config"

# Start from the repository's existing NEXORA system defaults.
cp -a "$ROOT_DIR/config/." "$WORK_DIR/config/"
mkdir -p "$WORK_DIR/config/includes.chroot"
mkdir -p "$WORK_DIR/config/package-lists"

# Debian Trixie moved ISOLINUX and Syslinux BIOS modules to /usr/lib.
# Override live-build's legacy bootloader links so they resolve inside chroot.
BOOTLOADER_TEMPLATE="/usr/share/live/build/bootloaders/isolinux"
BOOTLOADER_OVERRIDE="$WORK_DIR/config/bootloaders/isolinux"
if [[ ! -d "$BOOTLOADER_TEMPLATE" ]]; then
    echo "live-build ISOLINUX template is missing: $BOOTLOADER_TEMPLATE" >&2
    exit 1
fi
mkdir -p "$BOOTLOADER_OVERRIDE"
cp -a "$BOOTLOADER_TEMPLATE/." "$BOOTLOADER_OVERRIDE/"
ln -sfn /usr/lib/ISOLINUX/isolinux.bin "$BOOTLOADER_OVERRIDE/isolinux.bin"
for module in "$BOOTLOADER_OVERRIDE"/*.c32; do
    [[ -e "$module" || -L "$module" ]] || continue
    module_name="$(basename "$module")"
    ln -sfn "/usr/lib/syslinux/modules/bios/$module_name" "$module"
done

# Merge the complete NEXORA desktop overlay into the live root filesystem.
cp -a "$ROOT_DIR/installer/desktop-overlay/." "$WORK_DIR/config/includes.chroot/"
cp "$ROOT_DIR/config/package-lists/nexora-live.list.chroot" \
    "$WORK_DIR/config/package-lists/nexora-live.list.chroot"

# Make both NEXORA entry points executable in the final live image.
chmod 0755 "$WORK_DIR/config/includes.chroot"/usr/bin/nexora-* \
    "$WORK_DIR/config/includes.chroot/usr/local/sbin/nexora-postinstall" \
    "$WORK_DIR/config/includes.chroot/usr/lib/nexora-installer/install-engine.py"

# Replace Debian's stock boot splash with NEXORA artwork in BIOS and UEFI menus.
mkdir -p "$WORK_DIR/config/includes.binary/isolinux" \
    "$WORK_DIR/config/includes.binary/boot/grub"
python3 "$ROOT_DIR/scripts/create-installer-background.py" \
    "$WORK_DIR/config/includes.binary/isolinux/splash.png"
cp "$WORK_DIR/config/includes.binary/isolinux/splash.png" \
    "$WORK_DIR/config/includes.binary/boot/grub/splash.png"

# Identify the live edition clearly from the running system.
cat > "$WORK_DIR/config/includes.chroot/etc/nexora-release" <<'RELEASE'
NEXORA OS XFCE4 Live 0.1.0-alpha.3
Base: Debian GNU/Linux 13 (Trixie)
Desktop: XFCE4
Boot mode: Live hybrid ISO
Installer: NEXORA GTK Installer
Architecture: amd64
Tagline: Your Terminal. Your Universe.
RELEASE

mkdir -p "$WORK_DIR/config/includes.chroot/etc/skel/Desktop"
cp "$WORK_DIR/config/includes.chroot/usr/share/applications/nexora-installer.desktop" \
   "$WORK_DIR/config/includes.chroot/etc/skel/Desktop/Install-NEXORA.desktop"
chmod 0755 "$WORK_DIR/config/includes.chroot/etc/skel/Desktop/Install-NEXORA.desktop"

# Apply NEXORA XFCE defaults inside the image during the chroot stage.
mkdir -p "$WORK_DIR/config/hooks/normal"
cat > "$WORK_DIR/config/hooks/normal/9999-nexora-desktop.hook.chroot" <<'HOOK'
#!/bin/sh
set -eu
/usr/local/sbin/nexora-postinstall
HOOK
chmod 0755 "$WORK_DIR/config/hooks/normal/9999-nexora-desktop.hook.chroot"

cd "$WORK_DIR"

echo "==> Configuring Debian Live for NEXORA XFCE4..."
lb config \
    --mode debian \
    --distribution trixie \
    --initsystem systemd \
    --architectures amd64 \
    --mirror-bootstrap "https://deb.debian.org/debian" \
    --mirror-chroot "https://deb.debian.org/debian" \
    --mirror-binary "https://deb.debian.org/debian" \
    --keyring-packages "debian-archive-keyring" \
    --security false \
    --binary-images iso-hybrid \
    --debian-installer false \
    --debian-installer-gui false \
    --archive-areas "main contrib non-free non-free-firmware" \
    --bootappend-live "boot=live components locales=es_CL.UTF-8 keyboard-layouts=latam username=nexora" \
    --apt-recommends true \
    --iso-application "NEXORA OS XFCE4 Live" \
    --iso-publisher "NEXORA Project" \
    --iso-volume "NEXORA_XFCE4_LIVE"

echo "==> Applying Debian Trixie live-build Contents index compatibility fix..."
python3 "$ROOT_DIR/scripts/patch-live-build-contents-index.py"

echo "==> Building the XFCE4 Live system and native NEXORA GTK installer..."
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

# Apply the same NEXORA palette and splash behavior to the Live UEFI GRUB menu.
PATCHED_GRUB_CFG="$OUTPUT_DIR/nexora-live-grub.cfg"
BOOT_BRANDING_DIR="$OUTPUT_DIR/live-boot-branding"
BRANDED_ISO="$OUTPUT_DIR/nexora-os-xfce4-live-amd64-branded.iso"
python3 "$ROOT_DIR/scripts/brand-live-grub.py" "$OUTPUT_ISO" "$PATCHED_GRUB_CFG"
python3 "$ROOT_DIR/scripts/brand-live-syslinux.py" "$OUTPUT_ISO" "$BOOT_BRANDING_DIR"
SYSLINUX_CONFIG_PATH="$(cat "$BOOT_BRANDING_DIR/isolinux-path.txt")"
xorriso -indev "$OUTPUT_ISO" \
    -outdev "$BRANDED_ISO" \
    -map "$PATCHED_GRUB_CFG" /boot/grub/grub.cfg \
    -map "$BOOT_BRANDING_DIR/isolinux.cfg" "$SYSLINUX_CONFIG_PATH" \
    -boot_image any replay \
    -commit
mv "$BRANDED_ISO" "$OUTPUT_ISO"
rm -f "$PATCHED_GRUB_CFG"

echo "==> Checking the Live filesystem and boot media..."
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

# Extract the built live filesystem and assert the GTK installer is present.
VERIFY_DIR="$OUTPUT_DIR/installer-verification"
rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /live/filesystem.squashfs "$VERIFY_DIR/filesystem.squashfs" \
    >/dev/null 2>&1
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" usr/bin/nexora-installer \
    | grep -q 'NEXORA OS.*installation wizard' || {
    echo "The ISO does not contain the native NEXORA GTK installer." >&2
    exit 1
}
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" usr/lib/nexora-installer/install-engine.py \
    | grep -q 'NEXORA OS disk installation engine' || {
    echo "The native disk installation engine is missing from the ISO." >&2
    exit 1
}

# Verify the complete installed NEXORA desktop, not just the installer entry point.
verify_live_file() {
    local image_path="$1"
    if ! unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" "$image_path" >/dev/null 2>&1; then
        echo "Required NEXORA Live file is missing: /$image_path" >&2
        exit 1
    fi
}
for image_path in \
    usr/bin/nexora-ai usr/bin/nexora-center usr/bin/nexora-store \
    usr/bin/nexora-welcome usr/bin/nexora-updater \
    usr/local/sbin/nexora-postinstall \
    usr/share/applications/nexora-installer.desktop \
    usr/share/applications/nexora-ai.desktop \
    usr/share/applications/nexora-center.desktop \
    usr/share/applications/nexora-store.desktop \
    usr/share/applications/nexora-welcome.desktop \
    usr/share/applications/nexora-updater.desktop \
    usr/share/nexora/catalog.json usr/share/nexora/desktop-tools.json \
    usr/share/nexora/wallpapers.json \
    usr/share/themes/NEXORA-Ocean/gtk-3.0/gtk.css \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml \
    etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml \
    etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
    etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
do
    verify_live_file "$image_path"
done

for wallpaper in \
    nexora-default.svg nexora-aurora.svg nexora-nebula.svg nexora-horizon.svg \
    nexora-minimal.svg nexora-orbit.svg nexora-grid.svg nexora-midnight.svg
do
    unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" \
        "usr/share/backgrounds/nexora/$wallpaper" > "$VERIFY_DIR/$wallpaper" || {
        echo "NEXORA wallpaper is missing from the XFCE Live ISO: $wallpaper" >&2
        exit 1
    }
    python3 -c 'import sys,xml.etree.ElementTree as ET; ET.parse(sys.argv[1])' "$VERIFY_DIR/$wallpaper"
done

# Validate the actual panel layout and the default wallpaper from the built image.
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml \
    > "$VERIFY_DIR/xfce4-panel.xml"
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" \
    etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml \
    > "$VERIFY_DIR/xfce4-desktop.xml"
python3 - "$VERIFY_DIR/xfce4-panel.xml" "$VERIFY_DIR/xfce4-desktop.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

panel = ET.parse(sys.argv[1]).getroot()
props = {node.attrib.get("name"): node for node in panel.findall("property")}
assert [node.attrib["value"] for node in props["panels"].findall("value")] == ["1", "2"]
for panel_id in ("1", "2"):
    item = {node.attrib.get("name"): node for node in props[f"panel-{panel_id}"].findall("property")}
    assert item["mode"].attrib["value"] == "0"
    assert item["length"].attrib["value"] == "100"
    assert item["length-adjust"].attrib["value"] == "false"
    assert item["position-locked"].attrib["value"] == "true"
    assert item["autohide-behavior"].attrib["value"] == "0"
plugins = {node.attrib.get("name"): node for node in props["plugins"].findall("property")}
assert plugins["plugin-1"].attrib["value"] == "whiskermenu"
assert plugins["plugin-3"].attrib["value"] == "tasklist"
desktop = ET.parse(sys.argv[2]).getroot()
default = desktop.find("./property[@name='backdrop']/property[@name='screen0']/property[@name='monitor0']/property[@name='workspace0']/property[@name='last-image']")
assert default is not None and default.attrib["value"] == "/usr/share/backgrounds/nexora/nexora-default.svg"
print("PASS: built XFCE image has two fixed, visible NEXORA panels and the default NEXORA wallpaper.")
PY

# Confirm the essential desktop and NEXORA runtime dependencies are installed.
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" var/lib/dpkg/status > "$VERIFY_DIR/dpkg-status"
python3 - "$VERIFY_DIR/dpkg-status" <<'PY'
import re
import sys
from email.parser import Parser

raw_status = open(sys.argv[1], encoding="utf-8").read()
packages = [
    Parser().parsestr(block)
    for block in re.split(r"\\n\\s*\\n", raw_status)
    if block.strip()
]
required = {
    "task-xfce-desktop", "lightdm", "network-manager", "network-manager-gnome",
    "xfce4-whiskermenu-plugin", "xfce4-pulseaudio-plugin", "flatpak",
    "python3-gi", "gir1.2-gtk-3.0", "fonts-noto", "fonts-noto-color-emoji",
    "grub-pc-bin", "grub-efi-amd64-bin",
}
missing = sorted(name for name in required if not any(
    package.get("Package") == name and package.get("Status") == "install ok installed"
    for package in packages
))
if missing:
    raise SystemExit("Missing installed NEXORA/XFCE packages in Live ISO: " + ", ".join(missing))
print("PASS: XFCE, GTK, NetworkManager, Flatpak, fonts and bootloader packages are installed.")
PY

# The desktop launcher must invoke the native NEXORA GTK application.
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" \
    usr/share/applications/nexora-installer.desktop > "$VERIFY_DIR/nexora-installer.desktop"
grep -q '^Exec=python3 /usr/bin/nexora-installer
BOOT_SPLASH_VERIFY_DIR="$OUTPUT_DIR/boot-splash-verification"
rm -rf "$BOOT_SPLASH_VERIFY_DIR"
mkdir -p "$BOOT_SPLASH_VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /isolinux/splash.png "$BOOT_SPLASH_VERIFY_DIR/isolinux-splash.png" \
    -extract /boot/grub/splash.png "$BOOT_SPLASH_VERIFY_DIR/grub-splash.png" \
    >/dev/null 2>&1
cmp "$WORK_DIR/config/includes.binary/isolinux/splash.png" "$BOOT_SPLASH_VERIFY_DIR/isolinux-splash.png"
cmp "$WORK_DIR/config/includes.binary/isolinux/splash.png" "$BOOT_SPLASH_VERIFY_DIR/grub-splash.png"

LIVE_GRUB_VERIFY="$OUTPUT_DIR/live-grub-verification.cfg"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /boot/grub/grub.cfg "$LIVE_GRUB_VERIFY" >/dev/null 2>&1
grep -q '# NEXORA OS visual identity' "$LIVE_GRUB_VERIFY" || {
    echo "The XFCE Live GRUB menu is missing NEXORA styling." >&2
    exit 1
}
grep -q 'menu_color_highlight=white/blue' "$LIVE_GRUB_VERIFY" || {
    echo "The XFCE Live GRUB menu is missing NEXORA selection colors." >&2
    exit 1
}
grep -q 'background_image /boot/grub/splash.png' "$LIVE_GRUB_VERIFY" || {
    echo "The XFCE Live GRUB menu is not configured to use the NEXORA splash." >&2
    exit 1
}
rm -f "$LIVE_GRUB_VERIFY"

LIVE_ISOLINUX_VERIFY="$OUTPUT_DIR/live-isolinux-verification.cfg"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract "$SYSLINUX_CONFIG_PATH" "$LIVE_ISOLINUX_VERIFY" >/dev/null 2>&1
grep -q 'NEXORA OS visual identity' "$LIVE_ISOLINUX_VERIFY" || {
    echo "The XFCE Live BIOS menu is missing NEXORA styling." >&2
    exit 1
}
grep -q 'MENU BACKGROUND /isolinux/splash.png' "$LIVE_ISOLINUX_VERIFY" || {
    echo "The XFCE Live BIOS menu is not configured to use the NEXORA splash." >&2
    exit 1
}
grep -q 'MENU COLOR sel' "$LIVE_ISOLINUX_VERIFY" || {
    echo "The XFCE Live BIOS menu is missing NEXORA selection colors." >&2
    exit 1
}
rm -f "$LIVE_ISOLINUX_VERIFY"

SIZE_HUMAN="$(du -h "$OUTPUT_ISO" | awk '{print $1}')"
SHA256="$(sha256sum "$OUTPUT_ISO" | awk '{print $1}')"
printf '%s  %s\n' "$SHA256" "$(basename "$OUTPUT_ISO")" > "$OUTPUT_ISO.sha256"

echo
echo "==> NEXORA OS XFCE4 Live ISO created:"
echo "    $OUTPUT_ISO"
echo "    Size: $SIZE_HUMAN"
echo "    SHA256: $SHA256"
echo "    Live desktop: XFCE4"
echo "    Installer: native NEXORA GTK"
echo "    Base: Debian 13 Trixie"
 "$VERIFY_DIR/nexora-installer.desktop" || {
    echo "The NEXORA desktop shortcut does not launch the native installer." >&2
    exit 1
}

BOOT_SPLASH_VERIFY_DIR="$OUTPUT_DIR/boot-splash-verification"
rm -rf "$BOOT_SPLASH_VERIFY_DIR"
mkdir -p "$BOOT_SPLASH_VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /isolinux/splash.png "$BOOT_SPLASH_VERIFY_DIR/isolinux-splash.png" \
    -extract /boot/grub/splash.png "$BOOT_SPLASH_VERIFY_DIR/grub-splash.png" \
    >/dev/null 2>&1
cmp "$WORK_DIR/config/includes.binary/isolinux/splash.png" "$BOOT_SPLASH_VERIFY_DIR/isolinux-splash.png"
cmp "$WORK_DIR/config/includes.binary/isolinux/splash.png" "$BOOT_SPLASH_VERIFY_DIR/grub-splash.png"

LIVE_GRUB_VERIFY="$OUTPUT_DIR/live-grub-verification.cfg"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /boot/grub/grub.cfg "$LIVE_GRUB_VERIFY" >/dev/null 2>&1
grep -q '# NEXORA OS visual identity' "$LIVE_GRUB_VERIFY" || {
    echo "The XFCE Live GRUB menu is missing NEXORA styling." >&2
    exit 1
}
grep -q 'menu_color_highlight=white/blue' "$LIVE_GRUB_VERIFY" || {
    echo "The XFCE Live GRUB menu is missing NEXORA selection colors." >&2
    exit 1
}
grep -q 'background_image /boot/grub/splash.png' "$LIVE_GRUB_VERIFY" || {
    echo "The XFCE Live GRUB menu is not configured to use the NEXORA splash." >&2
    exit 1
}
rm -f "$LIVE_GRUB_VERIFY"

LIVE_ISOLINUX_VERIFY="$OUTPUT_DIR/live-isolinux-verification.cfg"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract "$SYSLINUX_CONFIG_PATH" "$LIVE_ISOLINUX_VERIFY" >/dev/null 2>&1
grep -q 'NEXORA OS visual identity' "$LIVE_ISOLINUX_VERIFY" || {
    echo "The XFCE Live BIOS menu is missing NEXORA styling." >&2
    exit 1
}
grep -q 'MENU BACKGROUND /isolinux/splash.png' "$LIVE_ISOLINUX_VERIFY" || {
    echo "The XFCE Live BIOS menu is not configured to use the NEXORA splash." >&2
    exit 1
}
grep -q 'MENU COLOR sel' "$LIVE_ISOLINUX_VERIFY" || {
    echo "The XFCE Live BIOS menu is missing NEXORA selection colors." >&2
    exit 1
}
rm -f "$LIVE_ISOLINUX_VERIFY"

SIZE_HUMAN="$(du -h "$OUTPUT_ISO" | awk '{print $1}')"
SHA256="$(sha256sum "$OUTPUT_ISO" | awk '{print $1}')"
printf '%s  %s\n' "$SHA256" "$(basename "$OUTPUT_ISO")" > "$OUTPUT_ISO.sha256"

echo
echo "==> NEXORA OS XFCE4 Live ISO created:"
echo "    $OUTPUT_ISO"
echo "    Size: $SIZE_HUMAN"
echo "    SHA256: $SHA256"
echo "    Live desktop: XFCE4"
echo "    Installer: native NEXORA GTK"
echo "    Base: Debian 13 Trixie"
