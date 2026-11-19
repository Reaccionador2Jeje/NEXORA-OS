#!/bin/sh
# Build the NEXORA OS Desktop live ISO.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo ./scripts/build.sh" >&2
    exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
    echo "live-build is missing. Install it with: apt install live-build" >&2
    exit 1
fi

if [ ! -x auto/config ]; then
    echo "auto/config must be executable. Run: chmod +x auto/config" >&2
    exit 1
fi

mkdir -p build-output

echo "==> Configuring NEXORA OS for Debian 13 Trixie (amd64)..."
lb config

echo "==> Building the live ISO. This may take a while..."
lb build

iso=$(find "$ROOT_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)
if [ -z "$iso" ]; then
    echo "Build finished, but no ISO was found in the project root." >&2
    exit 1
fi

destination="$ROOT_DIR/build-output/$(basename "$iso")"
mv "$iso" "$destination"

echo "==> NEXORA OS image created:"
echo "    $destination"
