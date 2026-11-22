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
check_file scripts/test-qemu-boot.sh
check_file installer/README.md
check_file installer/profiles/minimal.tasksel
check_file installer/profiles/desktop.tasksel

sh -n scripts/build.sh scripts/build-netinst.sh scripts/test-qemu-boot.sh scripts/validate-config.sh

grep -q 'DEBIAN_FRONTEND=gtk' installer/README.md || fail "GTK frontend must be documented."
grep -q 'tasksel' installer/profiles/minimal.tasksel || fail "Minimal tasksel profile is missing."
grep -q 'xfce-desktop' installer/profiles/desktop.tasksel || fail "XFCE tasksel profile is missing."
grep -q 'installer-amd64/current/images/netboot/gtk' scripts/build-netinst.sh || fail "Build must use the official Debian GTK netboot image."
grep -q 'boot_image any replay' scripts/build-netinst.sh || fail "ISO boot metadata must be preserved."
grep -q 'NEXORA_MINIMAL' scripts/build-netinst.sh || fail "NEXORA ISO volume label is missing."

if grep -Eq 'lb config|lb build|live-build' scripts/build.sh scripts/build-netinst.sh; then
    fail "Minimal netinst build must not invoke Debian Live."
fi

printf '\nNEXORA GTK netinst static checks passed. The actual ISO still needs CI and interactive QEMU testing.\n'
