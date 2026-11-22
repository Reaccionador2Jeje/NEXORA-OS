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
check_file scripts/check-dependencies.sh
check_file scripts/clean.sh
check_file scripts/test-qemu-boot.sh
check_file installer/README.md
check_file installer/profiles/minimal.md
check_file installer/profiles/desktop.md
check_file installer/preseed/minimal.cfg
check_file installer/preseed/desktop.cfg
check_file installer/BOOT-OPTIONS.md
check_file installer/preseed/minimal.cfg
check_file installer/preseed/desktop.cfg
check_file installer/BOOT-OPTIONS.md

sh -n scripts/build.sh scripts/build-netinst.sh scripts/check-dependencies.sh scripts/clean.sh scripts/test-qemu-boot.sh scripts/validate-config.sh

grep -q 'DEBIAN_FRONTEND=gtk' installer/README.md || fail "GTK frontend must be documented."
grep -q 'standard system utilities' installer/profiles/minimal.md || fail "Minimal task selection guidance is missing."
grep -q 'xfce-desktop' installer/profiles/desktop.md || fail "XFCE task selection guidance is missing."
grep -q 'installer-amd64/current/images/netboot/gtk' scripts/build-netinst.sh || fail "Build must use the official Debian GTK netboot image."
grep -q 'boot_image any replay' scripts/build-netinst.sh || fail "ISO boot metadata must be preserved."
grep -q 'NEXORA_MINIMAL' scripts/build-netinst.sh || fail "NEXORA ISO volume label is missing."
grep -q 'minimal.cfg' scripts/build-netinst.sh || fail "Minimal preseed profile is not embedded."
grep -q 'desktop.cfg' scripts/build-netinst.sh || fail "Desktop preseed profile is not embedded."
grep -q 'standardgrep -q 'minimal.cfg' scripts/build-netinst.sh || fail "Minimal preseed profile is not embedded."
grep -q 'desktop.cfg' scripts/build-netinst.sh || fail "Desktop preseed profile is not embedded."
grep -q 'standard
if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then
    fail "Minimal netinst build must not invoke Debian Live."
fi

printf '\nNEXORA GTK netinst static checks passed. The actual ISO still needs CI and interactive QEMU testing.\n'
 installer/preseed/minimal.cfg || fail "Minimal preseed must select standard utilities only."
grep -q 'standard, xfce-desktop' installer/preseed/desktop.cfg || fail "XFCE preseed task selection is missing."
grep -q 'partman/confirm_write_new_label boolean false' installer/preseed/minimal.cfg || fail "Minimal profile must not auto-confirm partition labels."
grep -q 'partman/confirm_write_new_label boolean false' installer/preseed/desktop.cfg || fail "Desktop profile must not auto-confirm partition labels."

if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then
    fail "Minimal netinst build must not invoke Debian Live."
fi

printf '\nNEXORA GTK netinst static checks passed. The actual ISO still needs CI and interactive QEMU testing.\n'
 installer/preseed/minimal.cfg || fail "Minimal preseed must select standard utilities only."
grep -q 'standard, xfce-desktop' installer/preseed/desktop.cfg || fail "XFCE preseed task selection is missing."
grep -q 'minimal.cfg' scripts/build-netinst.sh || fail "Minimal preseed profile is not embedded."
grep -q 'desktop.cfg' scripts/build-netinst.sh || fail "Desktop preseed profile is not embedded."
grep -q 'standard
if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then
    fail "Minimal netinst build must not invoke Debian Live."
fi

printf '\nNEXORA GTK netinst static checks passed. The actual ISO still needs CI and interactive QEMU testing.\n'
 installer/preseed/minimal.cfg || fail "Minimal preseed must select standard utilities only."
grep -q 'standard, xfce-desktop' installer/preseed/desktop.cfg || fail "XFCE preseed task selection is missing."
grep -q 'partman/confirm_write_new_label boolean false' installer/preseed/minimal.cfg || fail "Minimal profile must not auto-confirm partition labels."
grep -q 'partman/confirm_write_new_label boolean false' installer/preseed/desktop.cfg || fail "Desktop profile must not auto-confirm partition labels."

if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then
    fail "Minimal netinst build must not invoke Debian Live."
fi

printf '\nNEXORA GTK netinst static checks passed. The actual ISO still needs CI and interactive QEMU testing.\n'
