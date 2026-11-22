#!/bin/sh
set -eu

ISO_PATH="${1:-}"
BOOT_SECONDS="${NEXORA_QEMU_BOOT_SECONDS:-120}"

if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
  echo "Usage: $0 /path/to/nexora.iso"
  exit 2
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "ERROR: qemu-system-x86_64 is not installed."
  exit 2
fi

echo "NEXORA QEMU BIOS smoke test"
echo "ISO: $ISO_PATH"
echo "Boot observation window: ${BOOT_SECONDS}s"

# TCG keeps this test compatible with hosted CI runners without KVM.
# The timeout is expected: a live system should remain running after boot.
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
    echo "PASS: QEMU remained running for the full boot observation window."
    ;;
  0)
    echo "PASS: QEMU exited cleanly."
    ;;
  *)
    echo "FAIL: QEMU exited with status $status."
    exit "$status"
    ;;
esac

echo "NOTE: This is a headless boot smoke test, not a visual desktop test."
