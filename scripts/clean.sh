#!/bin/sh
# Clean generated NEXORA ISO artifacts and an interrupted Eggs remaster.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root: sudo ./scripts/clean.sh" >&2
    exit 1
fi

if command -v eggs >/dev/null 2>&1; then
    eggs destroy
fi

rm -f "$ROOT_DIR"/build-output/*.iso

echo "NEXORA OS ISO artifacts cleaned."
