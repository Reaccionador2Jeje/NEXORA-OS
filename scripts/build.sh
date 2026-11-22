#!/bin/sh
# Build the NEXORA OS Minimal terminal-only live ISO.
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

mkdir -p build-output

echo "==> Configuring NEXORA OS Minimal 0.1.0 (Debian Trixie / amd64 / terminal-only)..."
lb config

echo "==> Building the NEXORA Minimal ISO..."
lb build

iso=$(find "$ROOT_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)
if [ -z "$iso" ]; then
    echo "Build finished, but no ISO was found in the project root." >&2
    exit 1
fi

destination="$ROOT_DIR/build-output/$(basename "$iso")"
mv "$iso" "$destination"

size=$(du -h "$destination" | awk '{print $1}')
echo "==> NEXORA OS Minimal image created:"
echo "    $destination"
echo "    ISO size: $size"
