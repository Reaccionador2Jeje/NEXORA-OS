#!/bin/sh
# Inspect known Debian Installer GTK mini ISO boot-menu locations.
set -eu
if [ "$#" -ne 1 ]; then echo "Usage: sh scripts/inspect-boot-layout.sh <iso-path>" >&2; exit 2; fi
ISO=$1
[ -s "$ISO" ] || { echo "ISO does not exist or is empty: $ISO" >&2; exit 1; }
command -v xorriso >/dev/null 2>&1 || { echo "Required command is missing: xorriso" >&2; exit 1; }
echo "==> ISO root:"
xorriso -indev "$ISO" -ls / 2>&1
for path in /isolinux /syslinux /boot /boot/grub /EFI /EFI/BOOT; do
  echo
  echo "==> $path"
  xorriso -indev "$ISO" -ls "$path" 2>&1 || true
done
echo
echo "Inspection only: no bootloader configuration has been changed."
