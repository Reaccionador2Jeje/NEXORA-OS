#!/bin/sh
# Fast static checks for the NEXORA OS live-build source tree.
# This does not build or boot-test an ISO.

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

check_file() {
    [ -s "$1" ] || fail "Required file is missing or empty: $1"
    printf '[OK] %s\n' "$1"
}

check_file auto/config
check_file config/package-lists/nexora-desktop.list.chroot
check_file config/includes.chroot/etc/nexora-release
check_file config/includes.chroot/etc/issue
check_file config/includes.chroot/etc/motd
check_file branding/logo/nexora-logo.svg
check_file branding/logo/nexora-icon.svg
check_file branding/wallpapers/nexora-default.svg
check_file config/includes.chroot/usr/share/nexora/branding/nexora-logo.svg
check_file config/includes.chroot/usr/share/nexora/branding/nexora-icon.svg
check_file config/includes.chroot/usr/share/wallpapers/NEXORA/metadata.json
check_file config/includes.chroot/usr/share/wallpapers/NEXORA/contents/images/1920x1080.svg
check_file config/includes.chroot/etc/hostname
check_file config/includes.chroot/etc/default/keyboard

grep -q -- '--distribution trixie' auto/config || fail "Distribution must remain Debian Trixie."
grep -q -- '--architecture amd64' auto/config || fail "Initial ISO architecture must remain amd64."
grep -q 'task-kde-desktop' config/package-lists/nexora-desktop.list.chroot || fail "KDE desktop task is missing."
grep -q '^sddm$' config/package-lists/nexora-desktop.list.chroot || fail "SDDM display manager package is missing."
grep -q 'NEXORA OS' config/includes.chroot/etc/nexora-release || fail "NEXORA release identity is missing."

printf '\nNEXORA OS configuration checks passed. ISO build and boot tests are still required.\n'
