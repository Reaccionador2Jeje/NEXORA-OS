#!/bin/sh
# Static validation for the NEXORA GTK netinst build pipeline.
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }
check_file() {
    [ -s "$1" ] || fail "Required file is missing or empty: $1"
    printf '[OK] %s\n' "$1"
}

check_file scripts/build.sh
check_file scripts/build-netinst.sh
check_file scripts/build-live.sh
check_file config/package-lists/nexora-live.list.chroot
check_file installer/desktop-overlay/usr/share/applications/nexora-installer.desktop
check_file scripts/check-dependencies.sh
check_file scripts/clean.sh
check_file scripts/install-nexora-desktop.sh
check_file scripts/test-qemu-boot.sh
check_file scripts/inspect-boot-layout.sh
check_file scripts/create-installer-background.py
check_file installer/README.md
check_file installer/profiles/minimal.md
check_file installer/profiles/desktop.md
check_file installer/preseed/minimal.cfg
check_file installer/preseed/desktop.cfg
check_file installer/BOOT-OPTIONS.md
check_file installer/BOOT-MENU-DESIGN.md
check_file installer/desktop-overlay/usr/local/sbin/nexora-postinstall
check_file installer/desktop-overlay/usr/bin/nexora-ai
check_file installer/desktop-overlay/usr/bin/nexora-center
check_file installer/desktop-overlay/usr/bin/nexora-store
check_file installer/desktop-overlay/usr/bin/nexora-installer
check_file installer/desktop-overlay/usr/share/applications/nexora-installer.desktop
check_file installer/desktop-overlay/usr/bin/nexora-welcome
check_file installer/desktop-overlay/usr/bin/nexora-updater
check_file installer/desktop-overlay/usr/share/applications/nexora-updater.desktop
check_file tests/test-nexora-desktop.py
check_file installer/desktop-overlay/usr/share/backgrounds/nexora/nexora-aurora.svg
check_file installer/desktop-overlay/usr/share/themes/NEXORA-Ocean/gtk-3.0/gtk.css
check_file installer/desktop-overlay/usr/share/backgrounds/nexora/nexora-nebula.svg
check_file installer/desktop-overlay/usr/share/applications/nexora-ai.desktop
check_file installer/desktop-overlay/usr/share/applications/nexora-center.desktop
check_file installer/desktop-overlay/etc/xdg/autostart/nexora-polkit-agent.desktop
check_file installer/desktop-overlay/usr/share/pixmaps/nexora-icon.svg

bash -n scripts/build-live.sh
sh -n scripts/build.sh scripts/build-netinst.sh scripts/check-dependencies.sh scripts/clean.sh scripts/test-qemu-boot.sh scripts/inspect-boot-layout.sh scripts/validate-config.sh scripts/install-nexora-desktop.sh installer/desktop-overlay/usr/local/sbin/nexora-postinstall installer/desktop-overlay/usr/bin/nexora-welcome installer/desktop-overlay/usr/bin/nexora-updater

grep -q 'Debian Installer GTK' installer/README.md || fail "GTK netinst installer must be documented."
grep -q -- '--debian-installer live' scripts/build-live.sh || fail "XFCE4 must be built with Debian Live Installer support."
grep -q -- '--initsystem systemd' scripts/build-live.sh || fail "XFCE4 Live must use the systemd init backend."
grep -q 'Exec=python3 /usr/bin/nexora-installer' installer/desktop-overlay/usr/share/applications/nexora-installer.desktop || fail "Branded installer welcome entry is missing."
grep -q 'debian-installer-launcher' installer/desktop-overlay/usr/bin/nexora-installer || fail "Branded installer must launch Debian Installer Live."
grep -q 'task-xfce-desktop' config/package-lists/nexora-live.list.chroot || fail "Live image must include the XFCE desktop task."
grep -q 'debian-installer-launcher' config/package-lists/nexora-live.list.chroot || fail "Live image must include the desktop installer launcher."
grep -q 'standard system utilities' installer/profiles/minimal.md || fail "Minimal task selection guidance is missing."
grep -q 'xfce-desktop' installer/profiles/desktop.md || fail "XFCE task selection guidance is missing."
grep -q 'installer-${ARCH}/current/images/netboot/gtk' scripts/build-netinst.sh || fail "Build must use the official Debian GTK netboot image."
grep -q 'boot_image any replay' scripts/build-netinst.sh || fail "ISO boot metadata must be preserved."
grep -q 'NEXORA_MINIMAL' scripts/build-netinst.sh || fail "NEXORA Minimal ISO volume label is missing."
grep -q 'NEXORA_XFCE' scripts/build-netinst.sh || fail "NEXORA XFCE ISO volume label is missing."
grep -q 'NEXORA_DEFAULT_PROFILE' scripts/brand-installer-boot.py || fail "Edition-specific boot profile selection is missing."
grep -q 'NEXORA OS XFCE Desktop' scripts/brand-installer-boot.py || fail "XFCE boot entry is missing."
grep -q -- '-map "$ROOT_DIR/installer/preseed" /nexora/preseed' scripts/build-netinst.sh || fail "Preseed directory is not embedded in the ISO."
grep -q 'minimal.cfg' scripts/build-netinst.sh || fail "Minimal preseed profile is not embedded."
grep -q 'desktop.cfg' scripts/build-netinst.sh || fail "Desktop preseed profile is not embedded."
grep -q ' -ls /nexora/preseed' scripts/build-netinst.sh || fail "Build must verify the embedded preseed directory."
grep -q 'nexora-installer-background.png' scripts/build-netinst.sh || fail "Build must verify the branded installer background."
grep -q '/isolinux/splash.png' scripts/build-netinst.sh || fail "Netinst BIOS splash must use NEXORA artwork."
grep -q '/boot/grub/splash.png' scripts/build-netinst.sh || fail "Netinst UEFI splash must use NEXORA artwork."
grep -q 'includes.binary/isolinux/splash.png' scripts/build-live.sh || fail "Live BIOS splash must use NEXORA artwork."
grep -q 'includes.binary/boot/grub/splash.png' scripts/build-live.sh || fail "Live UEFI splash must use NEXORA artwork."
grep -q -- '-map "$ROOT_DIR/installer/desktop-overlay" /nexora/desktop-overlay' scripts/build-netinst.sh || fail "Desktop overlay is not embedded in the ISO."
grep -q 'preseed/late_command' installer/preseed/desktop.cfg || fail "XFCE profile does not install the desktop overlay."
grep -q 'es_CL.UTF-8' installer/preseed/desktop.cfg || fail "Desktop installer locale must default to Chilean Spanish."
grep -q 'priority=high' installer/preseed/desktop.cfg || fail "Desktop profile must retain interactive installer questions."
python3 -c 'import ast,json,pathlib,xml.etree.ElementTree as ET; ast.parse(pathlib.Path("scripts/create-installer-background.py").read_text()); ast.parse(pathlib.Path("scripts/brand-installer-boot.py").read_text()); ast.parse(pathlib.Path("installer/desktop-overlay/usr/bin/nexora-installer").read_text()); [ast.parse(pathlib.Path(p).read_text()) for p in ["installer/desktop-overlay/usr/bin/nexora-ai", "installer/desktop-overlay/usr/bin/nexora-center", "installer/desktop-overlay/usr/bin/nexora-store"]]; json.loads(pathlib.Path("installer/desktop-overlay/usr/share/nexora/catalog.json").read_text()); [ET.parse(p) for p in pathlib.Path("installer/desktop-overlay").rglob("*.xml")]'
grep -q 'tasksel tasksel/first multiselect standard$' installer/preseed/minimal.cfg || fail "Minimal profile must select standard utilities only."
grep -q 'tasksel tasksel/first multiselect standard, xfce-desktop' installer/preseed/desktop.cfg || fail "XFCE profile task selection is missing."
if grep -Eq 'auto=true|priority=critical' installer/preseed/*.cfg installer/BOOT-OPTIONS.md; then
    fail "Profile boot options must preserve interactive installer questions."
fi

if grep -Eq 'partman-auto|partman/early_command|partman/confirm.*true' installer/preseed/*.cfg; then
    fail "Preseed profiles must not automate or silently confirm disk partitioning."
fi

if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then
    fail "Minimal netinst build must not invoke Debian Live."
fi

python3 tests/test-nexora-desktop.py

# The Minimal terminal install must be able to add the complete NEXORA XFCE desktop later.
grep -q 'task-xfce-desktop' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must install the Debian XFCE task."
grep -q 'lightdm' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must install LightDM."
grep -q 'nexora-postinstall' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must apply the NEXORA overlay."
grep -q 'nexora-desktop' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must register the nexora-desktop command."
grep -q 'Path("/usr/share/nexora/catalog.json")' installer/desktop-overlay/usr/bin/nexora-store || fail "NEXORA Store catalog path must match the installed overlay."

for panel in config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml installer/desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml; do
    [ "$(grep -c '<property name="mode" type="uint" value="0"/>' "$panel")" -eq 2 ] || fail "Both NEXORA panels must be horizontal in $panel."
    [ "$(grep -c '<property name="length-adjust" type="bool" value="false"/>' "$panel")" -eq 2 ] || fail "Both NEXORA panels must keep fixed lengths in $panel."
    [ "$(grep -c '<property name="length" type="uint" value="100"/>' "$panel")" -eq 2 ] || fail "Both NEXORA panels must span the full width in $panel."
    grep -q '<property name="plugin-3" type="string" value="tasklist">' "$panel" || fail "The NEXORA window task list is missing in $panel."
done

printf '\nNEXORA netinst and XFCE4 Live static checks passed. A real ISO build and interactive install test are still required.\n'
