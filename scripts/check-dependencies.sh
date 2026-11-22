#!/bin/sh
# Check the host tools required for the NEXORA GTK netinst build.
set -eu
missing=0
for command in curl xorriso cpio gzip sha256sum qemu-system-x86_64; do
    if command -v "$command" >/dev/null 2>&1; then
        printf '[OK]      %s\n' "$command"
    else
        printf '[MISSING] %s\n' "$command"
        missing=1
    fi
done
if [ "$missing" -ne 0 ]; then
    echo
    echo "Install the required tools with:"
    echo "  sudo apt update"
    echo "  sudo apt install curl xorriso cpio gzip qemu-system-x86 qemu-utils"
    exit 1
fi
printf '\nAll NEXORA GTK netinst build tools are available.\n'
