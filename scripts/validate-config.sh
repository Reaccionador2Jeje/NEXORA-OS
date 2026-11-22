#!/bin/sh
# Static validation for NEXORA OS Minimal. Does not build or boot-test an ISO.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }
check_file() {
    [ -s "$1" ] || fail "Required file is missing or empty: $1"
    printf '[OK] %s\n' "$1"
}
check_package() {
    grep -qx "$1" config/package-lists/nexora-minimal.list.chroot ||
        fail "Required package is missing: $1"
    printf '[OK] package %s\n' "$1"
}
reject_package() {
    if grep -qx "$1" config/package-lists/nexora-minimal.list.chroot; then
        fail "Forbidden package in Minimal image: $1"
    fi
    printf '[OK] excluded %s\n' "$1"
}

check_file auto/config
check_file config/package-lists/nexora-minimal.list.chroot
check_file config/archives/nexora-security.list.chroot
check_file config/archives/nexora-security.list.binary
check_file config/includes.chroot/etc/nexora-release
check_file branding/logo/nexora-logo.svg

grep -q -- '--distribution trixie' auto/config || fail "Base must remain Debian Trixie."
grep -q -- '--architecture amd64' auto/config || fail "Architecture must remain amd64."
grep -q -- '--apt-recommends false' auto/config || fail "APT recommends must remain disabled."
grep -q -- '--security false' auto/config || fail "Use the explicit Trixie security source."
grep -q -- '--linux-packages none' auto/config || fail "Disable live-build kernel discovery."
grep -q -- '--initsystem systemd' auto/config || fail "Minimal must use systemd."
grep -q -- '--firmware-binary false' auto/config || fail "Firmware must remain excluded from the minimal ISO."
grep -q -- '--firmware-chroot false' auto/config || fail "Firmware must remain excluded from the minimal filesystem."
grep -q '^deb http://security.debian.org/debian-security trixie-security main$' config/archives/nexora-security.list.chroot || fail "Incorrect chroot security repository."
grep -q '^deb http://security.debian.org/debian-security trixie-security main$' config/archives/nexora-security.list.binary || fail "Incorrect binary security repository."
if grep -R -n 'trixie/updates' auto config; then
    fail "Obsolete Debian security suite detected."
fi

sh -n auto/config scripts/build.sh scripts/check-dependencies.sh scripts/clean.sh scripts/validate-config.sh

for package in live-boot live-config live-config-systemd live-tools systemd-sysv user-setup linux-image-amd64 bash coreutils util-linux procps iproute2 ifupdown isc-dhcp-client locales keyboard-configuration console-setup apt ca-certificates; do
    check_package "$package"
done
for package in live-config-sysvinit sysvinit-core xfce4-session xfce4-panel xserver-xorg lightdm chromium flatpak plasma-desktop task-kde-desktop; do
    reject_package "$package"
done

printf '\nNEXORA OS Minimal static checks passed. ISO size and bootability still require CI validation.\n'
