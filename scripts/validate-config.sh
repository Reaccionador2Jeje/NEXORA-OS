#!/bin/sh
# Clean static validation for NEXORA Minimal and XFCE4 Live.
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"
fail() { printf '[FAIL] %s\n' "$1" >&2; exit 1; }
check_file() { [ -s "$1" ] || fail "Required file is missing or empty: $1"; printf '[OK] %s\n' "$1"; }

for file in \
    scripts/build.sh scripts/build-netinst.sh scripts/build-live.sh \
    scripts/check-dependencies.sh scripts/clean.sh scripts/test-qemu-boot.sh \
    scripts/inspect-boot-layout.sh scripts/create-installer-background.py \
    scripts/brand-installer-boot.py scripts/patch-live-build-contents-index.py \
    scripts/install-nexora-desktop.sh scripts/validate-config.sh scripts/publish-sourceforge.sh \
    config/package-lists/nexora-live.list.chroot installer/README.md \
    installer/profiles/minimal.md installer/profiles/desktop.md \
    installer/preseed/minimal.cfg installer/preseed/desktop.cfg \
    installer/BOOT-OPTIONS.md installer/BOOT-MENU-DESIGN.md \
    installer/desktop-overlay/usr/local/sbin/nexora-postinstall \
    installer/desktop-overlay/usr/bin/nexora-installer \
    installer/desktop-overlay/usr/lib/nexora-installer/install-engine.py \
    installer/desktop-overlay/usr/share/applications/nexora-installer.desktop \
    installer/desktop-overlay/usr/share/nexora/catalog.json \
    installer/desktop-overlay/usr/share/backgrounds/nexora/nexora-default.svg \
    installer/desktop-overlay/usr/share/themes/NEXORA-Ocean/gtk-3.0/gtk.css \
    tests/test-nexora-desktop.py tests/test-live-build-contents-index.py tests/test-nexora-installer.py
do check_file "$file"; done

bash -n scripts/build-live.sh
sh -n scripts/build.sh scripts/build-netinst.sh scripts/check-dependencies.sh \
    scripts/clean.sh scripts/test-qemu-boot.sh scripts/inspect-boot-layout.sh \
    scripts/validate-config.sh scripts/install-nexora-desktop.sh scripts/publish-sourceforge.sh \
    installer/desktop-overlay/usr/local/sbin/nexora-postinstall

# XFCE4 Live uses the native NEXORA installer.
grep -q -- '--debian-installer false' scripts/build-live.sh || fail "XFCE4 Live must disable Debian Installer."
grep -q -- '--debian-installer-gui false' scripts/build-live.sh || fail "XFCE4 Live must disable Debian Installer GUI."
grep -q 'NEXORA GTK Installer' scripts/build-live.sh || fail "Live release metadata must name the NEXORA installer."
grep -q 'unsquashfs' scripts/build-live.sh || fail "Live ISO must verify native installer files."
grep -q 'patch-live-build-contents-index.py' scripts/build-live.sh || fail "Live build must retain Contents index compatibility."
grep -q 'NEXORA OS.*installation wizard' installer/desktop-overlay/usr/bin/nexora-installer || fail "Native GTK wizard is missing."
grep -q 'install-engine.py' installer/desktop-overlay/usr/bin/nexora-installer || fail "GTK wizard must invoke the NEXORA engine."
grep -q 'parted' installer/desktop-overlay/usr/lib/nexora-installer/install-engine.py || fail "Native partition engine is missing."
grep -q 'grub-install' installer/desktop-overlay/usr/lib/nexora-installer/install-engine.py || fail "Native bootloader setup is missing."
if grep -q 'debian-installer-launcher' installer/desktop-overlay/usr/bin/nexora-installer config/package-lists/nexora-live.list.chroot scripts/build-live.sh; then
    fail "XFCE4 Live must not invoke or package Debian Installer."
fi
for package in rsync parted dosfstools e2fsprogs grub-pc-bin grub-efi-amd64-bin pkexec python3-gi gir1.2-gtk-3.0 locales keyboard-configuration tzdata; do
    grep -qx "$package" config/package-lists/nexora-live.list.chroot || fail "Native installer package missing: $package"
done

# XFCE panel layout.
for panel in config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml installer/desktop-overlay/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml; do
    check_file "$panel"
    [ "$(grep -c '<property name="mode" type="uint" value="0"/>' "$panel")" -eq 2 ] || fail "Both panels must be horizontal in $panel."
    [ "$(grep -c '<property name="length-adjust" type="bool" value="false"/>' "$panel")" -eq 2 ] || fail "Both panels must have fixed length in $panel."
    [ "$(grep -c '<property name="length" type="uint" value="100"/>' "$panel")" -eq 2 ] || fail "Both panels must span the screen in $panel."
    grep -q '<property name="plugin-3" type="string" value="tasklist">' "$panel" || fail "Window tasklist missing in $panel."
done

# Netinst must embed and explicitly select the NEXORA artwork on BIOS and UEFI.
grep -q 'installer-${ARCH}/current/images/netboot/gtk' scripts/build-netinst.sh || fail "Netinst must use official GTK netboot image."
grep -q 'NEXORA_DEFAULT_PROFILE' scripts/brand-installer-boot.py || fail "Edition-specific boot profile selection is missing."
grep -q 'insmod png' scripts/brand-installer-boot.py || fail "GRUB must load PNG support before the NEXORA splash."
grep -q 'background_image /nexora/nexora-installer-background.png' scripts/brand-installer-boot.py || fail "GRUB must select the NEXORA background."
grep -q 'menu background /nexora/nexora-installer-background.png' scripts/brand-installer-boot.py || fail "Syslinux must select the NEXORA background."
grep -q 'UI vesamenu.c32' scripts/brand-installer-boot.py || fail "BIOS must use the graphics-capable Syslinux menu."
grep -q 'ISOLINUX_CONFIG_PATH=$(cat "$BOOT_BRANDING_DIR/isolinux-path.txt")' scripts/build-netinst.sh || fail "Detected BIOS Syslinux config path must be used when embedding the menu."
grep -q 'UEFI GRUB menu is not configured' scripts/build-netinst.sh || fail "Netinst must verify the UEFI background reference."
grep -q 'BIOS Syslinux menu is not configured' scripts/build-netinst.sh || fail "Netinst must verify the BIOS background reference."
grep -q 'boot_image any replay' scripts/build-netinst.sh || fail "Netinst must preserve boot records."
grep -q -- '-map "$ROOT_DIR/installer/preseed" /nexora/preseed' scripts/build-netinst.sh || fail "Preseed profiles must be embedded."
grep -q -- '-map "$ROOT_DIR/installer/preseed" /nexora/preseed' scripts/build-netinst.sh || fail "Both preseed profiles must be embedded in the ISO."
grep -q 'preseed/late_command' installer/preseed/desktop.cfg || fail "Desktop preseed must apply NEXORA overlay."
grep -q 'es_CL.UTF-8' installer/preseed/desktop.cfg || fail "Desktop locale must default to Chilean Spanish."
grep -q 'priority=high' installer/preseed/desktop.cfg || fail "Desktop preseed must remain interactive."
if grep -Eq 'auto=true|priority=critical|partman-auto|partman/early_command|partman/confirm.*true' installer/preseed/*.cfg installer/BOOT-OPTIONS.md; then fail "Preseed must not silently automate disk partitioning."; fi
if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then fail "Minimal netinst must not invoke Debian Live."; fi

python3 -c 'import ast,json,pathlib,xml.etree.ElementTree as ET; paths=["scripts/create-installer-background.py","scripts/brand-installer-boot.py","installer/desktop-overlay/usr/bin/nexora-installer","installer/desktop-overlay/usr/lib/nexora-installer/install-engine.py","installer/desktop-overlay/usr/bin/nexora-ai","installer/desktop-overlay/usr/bin/nexora-center","installer/desktop-overlay/usr/bin/nexora-store"]; [ast.parse(pathlib.Path(p).read_text()) for p in paths]; json.loads(pathlib.Path("installer/desktop-overlay/usr/share/nexora/catalog.json").read_text()); [ET.parse(p) for p in pathlib.Path("installer/desktop-overlay").rglob("*.xml")]'
python3 tests/test-nexora-desktop.py
python3 tests/test-live-build-contents-index.py
python3 tests/test-nexora-installer.py

grep -q 'task-xfce-desktop' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must install XFCE."
grep -q 'lightdm' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must install LightDM."
grep -q 'nexora-postinstall' scripts/install-nexora-desktop.sh || fail "Minimal desktop installer must apply the overlay."
grep -q 'SOURCE_INSTALLER' scripts/install-nexora-desktop.sh || fail "nexora-desktop command must retain installer path."
grep -q 'chmod 0755 "$SCRIPT_PATH"' scripts/install-nexora-desktop.sh || fail "Desktop installer must register executable command."
grep -q 'Path("/usr/share/nexora/catalog.json")' installer/desktop-overlay/usr/bin/nexora-store || fail "NEXORA Store catalog path is inconsistent."
printf '\nNEXORA static validation passed. Full VM installation tests are still required.\n'
