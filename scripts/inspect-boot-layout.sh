#!/bin/sh
set -eu
ISO="${1:-build-output/nexora-os-minimal-netinst-amd64.iso}"
[ -s "$ISO" ] || { echo "ISO not found: $ISO" >&2; exit 1; }

echo "NEXORA boot layout inspection"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# xorriso -find requires an explicit -exec action; collect paths without
# letting a listing failure hide the more useful root-directory report.
listing=$(xorriso -indev "$ISO" -find / -type f -exec echo 2>&1) || {
    echo "Could not enumerate ISO files; showing its root instead." >&2
    listing=$(xorriso -indev "$ISO" -ls / 2>&1) || true
}
printf '%s\n' "$listing" | grep -Ei 'isolinux|syslinux|grub|efi|menu|cfg' || true

# Debian netboot images place Syslinux configuration in different paths
# across releases. Probe common locations and report only files that exist.
for file in \
    /isolinux.cfg /menu.cfg /isolinux/isolinux.cfg /isolinux/menu.cfg \
    /isolinux/stdmenu.cfg /isolinux/txt.cfg /isolinux/adtxt.cfg \
    /isolinux/spk.cfg /isolinux/drk.cfg \
    /boot/grub/grub.cfg /boot/grub/loopback.cfg; do
    out="$tmp/$(printf '%s' "$file" | tr '/' '_')"
    if xorriso -osirrox on -indev "$ISO" -extract "$file" "$out" >/dev/null 2>&1 && [ -s "$out" ]; then
        echo
        echo "==> CONFIG $file"
        sed -n '1,180p' "$out"
    fi
done

echo
echo "Inspection only: no bootloader configuration has been changed."
