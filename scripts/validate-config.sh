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
check_file config/includes.chroot/usr/local/bin/nexora-setup
check_file config/includes.chroot/usr/share/nexora/desktop-packages.list
check_file config/hooks/normal/0600-nexora-setup-permissions.hook.chroot
check_file config/includes.chroot/usr/bin/nexora-store
check_file config/includes.chroot/usr/bin/nexora-welcome
check_file config/includes.chroot/usr/share/applications/nexora-store.desktop
check_file config/includes.chroot/usr/share/applications/nexora-welcome.desktop
check_file config/includes.chroot/usr/share/nexora-store/catalog.json
check_file config/includes.chroot/usr/share/themes/NEXORA/gtk-3.0/gtk.css
check_file config/includes.chroot/usr/share/backgrounds/nexora/nexora-default.svg

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
bash -n config/includes.chroot/usr/local/bin/nexora-setup
sh -n config/hooks/normal/0600-nexora-setup-permissions.hook.chroot
python3 -m py_compile config/includes.chroot/usr/bin/nexora-store
if grep -Eq "^(xserver-xorg|xfce4-session|lightdm|chromium|flatpak)$" config/package-lists/nexora-minimal.list.chroot; then
    fail "Optional desktop package leaked into the Minimal base image."
fi
for package in xserver-xorg xfce4-session lightdm chromium flatpak network-manager python3-gi gir1.2-gtk-3.0; do
    grep -qx "$package" config/includes.chroot/usr/share/nexora/desktop-packages.list || fail "Optional desktop package missing: $package"
done

for package in live-boot live-config live-config-systemd live-tools systemd-sysv user-setup linux-image-amd64 bash coreutils util-linux procps iproute2 ifupdown isc-dhcp-client locales keyboard-configuration console-setup apt ca-certificates; do
    check_package "$package"
done
for package in live-config-sysvinit sysvinit-core xfce4-session xfce4-panel xserver-xorg lightdm chromium flatpak plasma-desktop task-kde-desktop; do
    reject_package "$package"
done

printf '\nNEXORA OS Minimal static checks passed. ISO size and bootability still require CI validation.\n'
