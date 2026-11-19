#!/bin/sh
# Clean generated live-build files. This does not delete project sources.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo ./scripts/clean.sh" >&2
    exit 1
fi

lb clean --purge
rm -f ./*.iso ./*.img ./*.img.* ./*.contents ./*.packages ./*.manifest

echo "NEXORA OS build artifacts cleaned."
