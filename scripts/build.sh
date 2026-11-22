#!/bin/sh
# Build the NEXORA OS Hyper Lightweight XFCE live ISO.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo ./scripts/build.sh" >&2
    exit 1
fi

for command in lb debootstrap mksquashfs xorriso; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "Required build command is missing: $command" >&2
        exit 1
    fi
done

if [ ! -x auto/config ]; then
    echo "auto/config must be executable. Run: chmod +x auto/config" >&2
    exit 1
fi

# GitHub's text-file API stores new hook files as 0644; live-build needs executable hooks.
find config/hooks -type f -name '*.hook.chroot' -exec chmod 0755 {} +

mkdir -p build-output

echo "==> Configuring NEXORA OS 0.2.0 (Debian Trixie / amd64 / XFCE4)..."
lb config

echo "==> Building the Hyper Lightweight ISO..."
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
