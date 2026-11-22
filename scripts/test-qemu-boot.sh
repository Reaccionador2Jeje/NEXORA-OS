#!/bin/sh
# QEMU ISO process smoke test. This does NOT prove that the guest OS booted.
set -eu

ISO_PATH="${1:-}"
BOOT_SECONDS="${NEXORA_QEMU_BOOT_SECONDS:-120}"

if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
    echo "Usage: $0 /path/to/nexora.iso" >&2
    exit 2
fi

case "$BOOT_SECONDS" in
    ''|*[!0-9]*)
        echo "NEXORA_QEMU_BOOT_SECONDS must be a positive integer." >&2
        exit 2
        ;;
esac
if [ "$BOOT_SECONDS" -le 0 ]; then
    echo "NEXORA_QEMU_BOOT_SECONDS must be greater than zero." >&2
    exit 2
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "ERROR: qemu-system-x86_64 is not installed." >&2
    exit 2
fi
if ! command -v timeout >/dev/null 2>&1; then
    echo "ERROR: timeout is not installed." >&2
    exit 2
fi

echo "NEXORA QEMU ISO process smoke test"
echo "ISO: $ISO_PATH"
echo "Observation window: ${BOOT_SECONDS}s"
echo "This test checks QEMU process stability only; it does not verify guest boot."

set +e
timeout --signal=TERM --kill-after=10s "${BOOT_SECONDS}s" \
    qemu-system-x86_64 \
        -machine accel=tcg \
        -cpu max \
        -m 4096 \
        -smp 2 \
        -cdrom "$ISO_PATH" \
        -boot order=d \
        -display none \
        -serial none \
        -monitor none \
        -no-reboot \
        -no-shutdown
status=$?
set -e

case "$status" in
    124|137)
        echo "PASS: QEMU remained alive for the complete observation window."
        ;;
    0)
        echo "QEMU exited cleanly before the observation window ended."
        ;;
    *)
        echo "FAIL: QEMU exited with status $status." >&2
        exit "$status"
        ;;
esac

echo "LIMITATION: A guest boot, login screen, XFCE session, and Plymouth graphics were NOT verified."
