#!/bin/sh
# Prepare a dedicated Debian 13 Trixie machine as a NEXORA OS build host.
# This modifies the host by installing the complete NEXORA desktop package set.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

fail() { echo "NEXORA prepare: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "Run on a disposable/dedicated Debian VM: sudo ./scripts/prepare-system.sh"
[ -r /etc/os-release ] || fail "Cannot detect the host distribution."
. /etc/os-release
[ "${ID:-}" = "debian" ] || fail "Only Debian is supported as the preparation host."
[ "${VERSION_CODENAME:-}" = "trixie" ] || fail "Expected Debian 13 Trixie."

manifest="$ROOT_DIR/config/package-lists/nexora-desktop.list.chroot"
includes="$ROOT_DIR/config/includes.chroot"
[ -s "$manifest" ] || fail "NEXORA desktop package manifest is missing."
[ -d "$includes" ] || fail "NEXORA system configuration directory is missing."

echo "==> Installing the NEXORA Desktop package set..."
apt-get update
packages=$(awk 'NF && $1 !~ /^#/ { print $1 }' "$manifest")
[ -n "$packages" ] || fail "No packages found in the NEXORA package manifest."
# Intentional word splitting: each non-comment manifest line is one apt package.
DEBIAN_FRONTEND=noninteractive apt-get install -y $packages

echo "==> Applying NEXORA system identity and desktop defaults..."
cp -a "$includes/." /
if [ -f /usr/bin/nexora-welcome ]; then
    chmod 0755 /usr/bin/nexora-welcome
fi

if command -v locale-gen >/dev/null 2>&1; then
    locale-gen
fi

if command -v systemctl >/dev/null 2>&1; then
    systemctl enable NetworkManager.service 2>/dev/null || true
    systemctl enable sddm.service 2>/dev/null || true
fi

echo "==> NEXORA base system prepared."
echo "==> Install the official Penguins' eggs package, then run:"
echo "    sudo ./scripts/check-dependencies.sh"
echo "    sudo eggs config"
echo "    sudo ./scripts/build.sh"
