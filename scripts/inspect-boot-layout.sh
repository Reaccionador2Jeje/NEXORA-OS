#!/bin/sh
# Inspect bootloader configuration paths in a built NEXORA ISO.
set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: sh scripts/inspect-boot-layout.sh <iso-path>" >&2
    exit 2
fi

ISO=$1
[ -s "$ISO" ] || {
    echo "ISO does not exist or is empty: $ISO" >&2
    exit 1
}
command -v xorriso >/dev/null 2>&1 || {
    echo "Required command is missing: xorriso" >&2
    exit 1
}

echo "==> Listing ISO bootloader-related configuration files..."
listing=$(xorriso -indev "$ISO" -find / -type f -print 2>&1)
printf '%s\n' "$listing"

matches=$(printf '%s\n' "$listing" | grep -Ei '/(isolinux|syslinux|boot/grub|efi)/.*(\.cfg|\.conf)$' || true)
if [ -z "$matches" ]; then
    echo "No common Syslinux/GRUB configuration path was detected." >&2
    echo "Do not patch the ISO until its boot structure has been inspected." >&2
    exit 1
fi

echo
echo "==> Candidate boot menu configuration paths:"
printf '%s\n' "$matches"
