#!/bin/sh
# Remove generated NEXORA netinst and Live build artifacts without touching sources.
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"
rm -f build-output/debian-installer-*-gtk-mini.iso
rm -f build-output/nexora-os-minimal-netinst-*.iso
echo "NEXORA GTK netinst artifacts cleaned."

rm -rf build-output/live-build
rm -f build-output/nexora-os-xfce4-live-amd64.iso build-output/nexora-os-xfce4-live-amd64.iso.sha256
echo "NEXORA Live artifacts cleaned."
