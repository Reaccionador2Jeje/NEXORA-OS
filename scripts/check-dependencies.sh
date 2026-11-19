#!/bin/sh
# Check the host tools required to build NEXORA OS.

set -eu

missing=0
for command in lb debootstrap mksquashfs xorriso; do
    if command -v "$command" >/dev/null 2>&1; then
        printf '[OK]      %s\n' "$command"
    else
        printf '[MISSING] %s\n' "$command"
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    printf '\nInstall the build dependencies with:\n'
    printf '  sudo apt update\n'
    printf '  sudo apt install live-build debootstrap squashfs-tools xorriso\n'
    exit 1
fi

printf '\nAll required build commands are available.\n'
