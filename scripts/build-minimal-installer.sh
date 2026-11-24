#!/usr/bin/env bash
# Build NEXORA Minimal as a bootable GTK installer environment (no XFCE desktop).
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build-output"
WORK_DIR="$OUTPUT_DIR/minimal-installer-build"
OUTPUT_ISO="$OUTPUT_DIR/nexora-os-minimal-netinst-amd64.iso"

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script as root: sudo ./scripts/build.sh" >&2
    exit 1
fi
for command in lb xorriso sha256sum unsquashfs; do
    command -v "$command" >/dev/null 2>&1 || {
        echo "Required command is missing: $command" >&2
        exit 1
    }
done

mkdir -p "$OUTPUT_DIR"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/config"
cp -a "$ROOT_DIR/installer/desktop-overlay/." "$WORK_DIR/config/includes.chroot/"
chmod 0755 "$WORK_DIR/config/includes.chroot/usr/bin/nexora-installer" "$WORK_DIR/config/includes.chroot/usr/lib/nexora-installer/install-engine.py"
mkdir -p "$WORK_DIR/config/package-lists" "$WORK_DIR/config/includes.chroot/etc/lightdm/lightdm.conf.d" "$WORK_DIR/config/includes.chroot/etc/skel/.config/openbox" "$WORK_DIR/config/includes.binary/isolinux" "$WORK_DIR/config/includes.binary/boot/grub"
cp "$ROOT_DIR/config/package-lists/nexora-minimal-installer.list.chroot" "$WORK_DIR/config/package-lists/nexora-minimal-installer.list.chroot"

# Launch the native installer automatically after the minimal graphical session starts.
cat > "$WORK_DIR/config/includes.chroot/etc/lightdm/lightdm.conf.d/50-nexora-autologin.conf" <<'LIGHTDM'
[Seat:*]
autologin-user=nexora
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
LIGHTDM

cat > "$WORK_DIR/config/includes.chroot/etc/skel/.config/openbox/autostart" <<'AUTOSTART'
#!/bin/sh
lxpolkit &
nm-applet &
(sleep 2; python3 /usr/bin/nexora-installer) &
AUTOSTART
chmod 0755 "$WORK_DIR/config/includes.chroot/etc/skel/.config/openbox/autostart"
mkdir -p "$WORK_DIR/config/includes.chroot/etc/systemd/system/graphical.target.wants" "$WORK_DIR/config/includes.chroot/etc/systemd/system/multi-user.target.wants"
ln -sfn /lib/systemd/system/graphical.target "$WORK_DIR/config/includes.chroot/etc/systemd/system/default.target"
ln -sfn /lib/systemd/system/lightdm.service "$WORK_DIR/config/includes.chroot/etc/systemd/system/graphical.target.wants/lightdm.service"
ln -sfn /lib/systemd/system/NetworkManager.service "$WORK_DIR/config/includes.chroot/etc/systemd/system/multi-user.target.wants/NetworkManager.service"

cat > "$WORK_DIR/config/includes.chroot/etc/nexora-release" <<'RELEASE'
NEXORA OS Minimal GTK Installer 0.1.0-alpha
Base: Debian GNU/Linux 13 (Trixie)
Desktop runtime: Openbox + GTK3
Installer: NEXORA Native GTK Installer
Architecture: amd64
Tagline: Your Terminal. Your Universe.
RELEASE

python3 "$ROOT_DIR/scripts/create-installer-background.py" "$WORK_DIR/config/includes.binary/isolinux/splash.png"
cp "$WORK_DIR/config/includes.binary/isolinux/splash.png" "$WORK_DIR/config/includes.binary/boot/grub/splash.png"

cd "$WORK_DIR"
echo "==> Configuring minimal Debian Live installer runtime..."
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
    --apt-recommends false \
    --iso-application "NEXORA OS Minimal Native GTK Installer" \
    --iso-publisher "NEXORA Project" \
    --iso-volume "NEXORA_MINIMAL"

echo "==> Building the NEXORA native GTK installer boot environment..."
lb build

BUILT_ISO="$WORK_DIR/live-image-amd64.hybrid.iso"
[[ -s "$BUILT_ISO" ]] || BUILT_ISO="$WORK_DIR/live-image-amd64.iso"
[[ -s "$BUILT_ISO" ]] || {
    echo "live-build did not produce the Minimal installer ISO." >&2
    find "$WORK_DIR" -maxdepth 2 -type f -name '*.iso' -print >&2
    exit 1
}
cp "$BUILT_ISO" "$OUTPUT_ISO"

# Apply the shared NEXORA boot theme to UEFI GRUB and BIOS Syslinux.
PATCHED_GRUB_CFG="$OUTPUT_DIR/nexora-minimal-grub.cfg"
BOOT_BRANDING_DIR="$OUTPUT_DIR/minimal-boot-branding"
BRANDED_ISO="$OUTPUT_DIR/nexora-os-minimal-netinst-amd64-branded.iso"
python3 "$ROOT_DIR/scripts/brand-live-grub.py" "$OUTPUT_ISO" "$PATCHED_GRUB_CFG"
python3 "$ROOT_DIR/scripts/brand-live-syslinux.py" "$OUTPUT_ISO" "$BOOT_BRANDING_DIR"
SYSLINUX_CONFIG_PATH="$(cat "$BOOT_BRANDING_DIR/isolinux-path.txt")"
xorriso -indev "$OUTPUT_ISO" \
    -outdev "$BRANDED_ISO" \
    -map "$PATCHED_GRUB_CFG" /boot/grub/grub.cfg \
    -map "$BOOT_BRANDING_DIR/isolinux.cfg" "$SYSLINUX_CONFIG_PATH" \
    -boot_image any replay -commit
mv "$BRANDED_ISO" "$OUTPUT_ISO"

echo "==> Verifying the native installer runtime inside the Minimal ISO..."
VERIFY_DIR="$OUTPUT_DIR/minimal-installer-verification"
rm -rf "$VERIFY_DIR"
mkdir -p "$VERIFY_DIR"
xorriso -osirrox on -indev "$OUTPUT_ISO" -extract /live/filesystem.squashfs "$VERIFY_DIR/filesystem.squashfs" >/dev/null 2>&1
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" usr/bin/nexora-installer | grep -q 'NEXORA OS.*installation wizard'
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" usr/lib/nexora-installer/install-engine.py | grep -q 'NEXORA OS disk installation engine'
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" etc/skel/.config/openbox/autostart > "$VERIFY_DIR/autostart"
grep -q 'python3 /usr/bin/nexora-installer' "$VERIFY_DIR/autostart"
unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" etc/lightdm/lightdm.conf.d/50-nexora-autologin.conf > "$VERIFY_DIR/lightdm.conf"
grep -q '^autologin-user=nexora$' "$VERIFY_DIR/lightdm.conf"
grep -q '^user-session=openbox$' "$VERIFY_DIR/lightdm.conf"

unsquashfs -cat "$VERIFY_DIR/filesystem.squashfs" var/lib/dpkg/status > "$VERIFY_DIR/dpkg-status"
python3 - "$VERIFY_DIR/dpkg-status" <<'PY'
import re, sys
from email.parser import Parser
raw = open(sys.argv[1], encoding="utf-8").read()
packages = [Parser().parsestr(block) for block in re.split(r"\n\s*\n", raw) if block.strip()]
required = {
    "live-boot", "lightdm", "lightdm-gtk-greeter", "openbox", "xserver-xorg",
    "network-manager", "network-manager-gnome", "xserver-xorg-video-all", "xserver-xorg-input-all", "python3", "python3-gi",
    "gir1.2-gtk-3.0", "rsync", "parted", "dosfstools", "e2fsprogs",
    "pkexec", "lxpolkit", "grub-pc-bin", "grub-efi-amd64-bin",
}
missing = sorted(name for name in required if not any(
    p.get("Package") == name and p.get("Status") == "install ok installed" for p in packages
))
if missing:
    raise SystemExit("Minimal native installer runtime is missing: " + ", ".join(missing))
print("PASS: Minimal GTK runtime, storage tools, NetworkManager and polkit are installed.")
PY

boot_report="$(xorriso -indev "$OUTPUT_ISO" -report_el_torito plain 2>&1 || true)"
printf '%s\\n' "$boot_report" | grep -qi 'El Torito'
BOOT_VERIFY="$OUTPUT_DIR/minimal-boot-verification"
mkdir -p "$BOOT_VERIFY"
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /boot/grub/grub.cfg "$BOOT_VERIFY/grub.cfg" \
    -extract "$SYSLINUX_CONFIG_PATH" "$BOOT_VERIFY/isolinux.cfg" >/dev/null 2>&1
grep -q '# NEXORA OS visual identity' "$BOOT_VERIFY/grub.cfg"
grep -q 'background_image /boot/grub/splash.png' "$BOOT_VERIFY/grub.cfg"
grep -q '# NEXORA OS visual identity' "$BOOT_VERIFY/isolinux.cfg"
grep -q 'MENU BACKGROUND /isolinux/splash.png' "$BOOT_VERIFY/isolinux.cfg"
grep -q 'MENU COLOR sel' "$BOOT_VERIFY/isolinux.cfg"
SIZE_HUMAN="$(du -h "$OUTPUT_ISO" | awk '{print $1}')"
SHA256="$(sha256sum "$OUTPUT_ISO" | awk '{print $1}')"
printf '%s  %s\\n' "$SHA256" "$(basename "$OUTPUT_ISO")" > "$OUTPUT_ISO.sha256"
echo "==> NEXORA Minimal native GTK installer ISO created:"
echo "    $OUTPUT_ISO"
echo "    Size: $SIZE_HUMAN"
echo "    SHA256: $SHA256"
echo "    Boot: Openbox + LightDM auto-login -> native NEXORA GTK installer"
