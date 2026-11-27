#!/bin/sh
# Check the host tools required to build NEXORA OS with Penguins' eggs.
set -eu

missing=0
for command in eggs dpkg; do
    if command -v "$command" >/dev/null 2>&1; then
        printf '[OK]      %s\n' "$command"
    else
        printf '[MISSING] %s\n' "$command"
        missing=1
    fi
done

if [ "$missing" -ne 0 ]; then
    printf '\nInstall the official Penguins\047 eggs package and Debian package tools.\n'
    exit 1
fi

if [ -r /etc/os-release ]; then
    . /etc/os-release
    if [ "${ID:-}" != "debian" ] || [ "${VERSION_CODENAME:-}" != "trixie" ]; then
        printf '[WARN] Build host is not Debian 13 Trixie.\n'
    else
        printf '[OK]      Debian 13 Trixie\n'
    fi
fi

eggs version
