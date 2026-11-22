#!/bin/sh
# Static validation for NEXORA OS. This does not build or boot-test an ISO.
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
        fail "Required package is missing: $1"
    printf '[OK] package %s\n' "$1"
}
reject_package() {
    if grep -qx "$1" config/package-lists/nexora-desktop.list.chroot; then
        fail "Forbidden package in lightweight image: $1"
    fi
    printf '[OK] excluded %s\n' "$1"
}

check_file auto/config
check_file config/package-lists/nexora-desktop.list.chroot
check_file config/includes.chroot/etc/nexora-release
check_file config/includes.chroot/etc/locale.gen
check_file config/includes.chroot/etc/default/locale
check_file config/includes.chroot/etc/default/keyboard
check_file config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf
check_file config/includes.chroot/etc/xdg/autostart/nexora-polkit-agent.desktop
check_file config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
check_file config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
check_file config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
check_file config/includes.chroot/usr/share/themes/NEXORA/gtk-3.0/gtk.css
check_file config/includes.chroot/usr/share/backgrounds/nexora/nexora-default.svg
check_file config/includes.chroot/usr/bin/nexora-welcome
check_file config/includes.chroot/usr/bin/nexora-store
check_file config/includes.chroot/usr/share/applications/nexora-store.desktop
check_file config/includes.chroot/usr/share/nexora-store/catalog.json
check_file config/hooks/normal/0500-enable-flathub.hook.chroot
check_file branding/logo/nexora-logo.svg
check_file branding/logo/nexora-icon.svg

grep -q -- '--distribution trixie' auto/config || fail "Distribution must remain Debian Trixie."
grep -q -- '--architecture amd64' auto/config || fail "Initial ISO architecture must remain amd64."
grep -q -- '--apt-recommends false' auto/config || fail "APT recommends must remain disabled for the lightweight profile."
sh -n auto/config scripts/build.sh scripts/check-dependencies.sh scripts/clean.sh scripts/validate-config.sh
sh -n config/hooks/normal/0500-enable-flathub.hook.chroot
python3 -c 'import ast, pathlib; ast.parse(pathlib.Path("config/includes.chroot/usr/bin/nexora-store").read_text(encoding="utf-8"))'
python3 -c 'import json, pathlib; json.loads(pathlib.Path("config/includes.chroot/usr/share/nexora-store/catalog.json").read_text(encoding="utf-8"))'

for package in xfce4-session xfce4-panel xfdesktop4 xfwm4 xfce4-settings thunar lightdm chromium flatpak adwaita-icon-theme pipewire-pulse python3-gi gir1.2-gtk-3.0 pkexec lxpolkit; do
    check_package "$package"
done
for package in task-kde-desktop sddm plasma-discover konsole dolphin supertux supertuxkart kmines kpat neverball; do
    reject_package "$package"
done

grep -q 'Desktop: XFCE4' config/includes.chroot/etc/nexora-release || fail "Release identity must declare XFCE4."
grep -qx 'es_CL.UTF-8 UTF-8' config/includes.chroot/etc/locale.gen || fail "Spanish (Chile) locale is not enabled."
grep -qx 'LANG=es_CL.UTF-8' config/includes.chroot/etc/default/locale || fail "Spanish (Chile) is not the default locale."
grep -q 'NEXORA' config/includes.chroot/etc/lightdm/lightdm-gtk-greeter.conf || fail "NEXORA greeter theme is not selected."
grep -q 'NEXORA Store' config/includes.chroot/usr/share/applications/nexora-store.desktop || fail "NEXORA Store launcher is missing."

printf '\nNEXORA XFCE and Store configuration checks passed. ISO build and boot tests are still required.\n'
