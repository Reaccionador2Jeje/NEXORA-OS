#!/bin/sh
# Static checks for the NEXORA OS source and Penguins' eggs integration.
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

check_package() {
    grep -qx "$1" config/package-lists/nexora-desktop.list.chroot ||
        fail "Required package is missing from the reference manifest: $1"
    printf '[OK] package %s\n' "$1"
}

check_file scripts/build.sh
check_file scripts/check-dependencies.sh
check_file docs/BUILDING.md
check_file config/package-lists/nexora-desktop.list.chroot
check_file config/includes.chroot/etc/nexora-release
check_file config/includes.chroot/etc/issue
check_file config/includes.chroot/etc/motd
check_file config/includes.chroot/etc/locale.gen
check_file config/includes.chroot/etc/default/locale
check_file config/includes.chroot/etc/default/keyboard
check_file config/includes.chroot/etc/xdg/kdeglobals
check_file config/includes.chroot/etc/sddm.conf.d/nexora.conf
check_file config/includes.chroot/usr/bin/nexora-welcome
check_file config/includes.chroot/usr/share/applications/nexora-welcome.desktop
check_file config/includes.chroot/usr/share/color-schemes/NEXORA.colors
check_file branding/logo/nexora-logo.svg
check_file branding/logo/nexora-icon.svg
check_file branding/wallpapers/nexora-default.svg

check_package task-kde-desktop
check_package sddm
check_package chromium
check_package kdialog
check_package kde-spectacle
check_package polkitd
check_package pkexec
check_package supertux
check_package supertuxkart

grep -q 'NEXORA OS' config/includes.chroot/etc/nexora-release || fail "NEXORA release identity is missing."
grep -q 'eggs remaster --target-dir' scripts/build.sh || fail "ISO builder is not using Penguins' eggs."
grep -q '/etc/nexora-release' scripts/build.sh || fail "Build safety check for NEXORA identity is missing."
grep -q 'Penguins' docs/BUILDING.md || fail "Penguins' eggs build documentation is missing."

grep -qx 'es_CL.UTF-8 UTF-8' config/includes.chroot/etc/locale.gen || fail "Spanish (Chile) locale is not enabled."
grep -qx 'LANG=es_CL.UTF-8' config/includes.chroot/etc/default/locale || fail "Spanish (Chile) is not the default locale."
grep -q 'ColorScheme=NEXORA' config/includes.chroot/etc/xdg/kdeglobals || fail "NEXORA KDE color scheme is not selected."

printf '\nNEXORA OS source checks passed. An Eggs remaster and VM boot test are still required.\n'
