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

grep -q -- '--distribution trixie' auto/config || fail "Distribution must remain Debian Trixie."
grep -q -- '--architecture amd64' auto/config || fail "Initial ISO architecture must remain amd64."
grep -qx 'task-kde-desktop' config/package-lists/nexora-desktop.list.chroot || fail "KDE desktop task is missing."
grep -qx 'sddm' config/package-lists/nexora-desktop.list.chroot || fail "SDDM display manager package is missing."
grep -qx 'chromium' config/package-lists/nexora-desktop.list.chroot || fail "Chromium browser package is missing."
grep -qx 'kdialog' config/package-lists/nexora-desktop.list.chroot || fail "KDialog is required by NEXORA Welcome."
grep -qx 'supertux' config/package-lists/nexora-desktop.list.chroot || fail "SuperTux game package is missing."
grep -qx 'supertuxkart' config/package-lists/nexora-desktop.list.chroot || fail "SuperTuxKart game package is missing."
grep -q 'NEXORA OS' config/includes.chroot/etc/nexora-release || fail "NEXORA release identity is missing."
grep -qx 'es_CL.UTF-8 UTF-8' config/includes.chroot/etc/locale.gen || fail "Spanish (Chile) locale is not enabled."
grep -qx 'LANG=es_CL.UTF-8' config/includes.chroot/etc/default/locale || fail "Spanish (Chile) is not the default locale."
grep -q 'ColorScheme=NEXORA' config/includes.chroot/etc/xdg/kdeglobals || fail "NEXORA KDE color scheme is not selected."

printf '\nNEXORA OS configuration checks passed. ISO build and boot tests are still required.\n'
