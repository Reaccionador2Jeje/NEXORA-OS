#!/bin/sh
set -eu
ISO="${1:-build-output/nexora-os-minimal-netinst-amd64.iso}"
[ -s "$ISO" ] || { echo "ISO not found: $ISO" >&2; exit 1; }
echo "NEXORA boot layout inspection"
listing=$(xorriso -indev "$ISO" -find / -type f -print 2>&1)
printf '%s\n' "$listing" | grep -Ei 'isolinux|syslinux|grub|efi|menu|cfg' || true
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
for file in /isolinux.cfg /menu.cfg /stdmenu.cfg /txt.cfg /adtxt.cfg /spk.cfg /drk.cfg /boot/grub/grub.cfg /boot/grub/loopback.cfg; do
    out="$tmp/$(printf '%s' "$file" | tr '/' '_')"
    if xorriso -osirrox on -indev "$ISO" -extract "$file" "$out" >/dev/null 2>&1 && [ -s "$out" ]; then
        echo
        echo "==> CONFIG $file"
        sed -n '1,180p' "$out"
    fi
done
echo
echo "Inspection only: no bootloader configuration has been changed."
