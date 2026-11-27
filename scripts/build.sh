#!/bin/sh
# Build a NEXORA OS live ISO with Penguins' eggs.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

fail() { echo "NEXORA ISO: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || fail "Run from the NEXORA system with sudo: sudo ./scripts/build.sh"
[ -r /etc/nexora-release ] || fail "NEXORA release marker missing (/etc/nexora-release). Refusing to remaster another system."

. /etc/os-release
[ "${ID:-}" = "debian" ] || fail "Build host must be Debian 13 Trixie. Detected: ${PRETTY_NAME:-unknown}"
[ "${VERSION_CODENAME:-}" = "trixie" ] || fail "Expected Debian 13 Trixie; detected: ${VERSION_CODENAME:-unknown}."

command -v eggs >/dev/null 2>&1 || fail "Penguins' eggs is not installed. Install the official penguins-eggs package first."
eggs version >/dev/null 2>&1 || fail "The eggs command could not report its version."

mkdir -p "$ROOT_DIR/build-output"

echo "==> Building NEXORA OS with Penguins' eggs..."
echo "==> Output directory: $ROOT_DIR/build-output"
echo "==> Standard Live mode is used; personal credentials are not cloned."

eggs remaster --target-dir "$ROOT_DIR/build-output"

iso=$(find "$ROOT_DIR/build-output" -maxdepth 1 -type f -name '*.iso' -print | sort | tail -n 1)
[ -n "$iso" ] || fail "Penguins' eggs finished without producing an ISO in build-output/."

version=$(awk 'NR == 1 { print $NF }' /etc/nexora-release)
[ -n "$version" ] || version="development"
arch=$(dpkg --print-architecture)
destination="$ROOT_DIR/build-output/nexora-os-$version-$arch.iso"

if [ "$iso" != "$destination" ]; then
    mv "$iso" "$destination"
fi

echo "==> NEXORA OS ISO created:"
echo "    $destination"
