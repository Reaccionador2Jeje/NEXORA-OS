#!/bin/sh
# Minimal GTK Netinst boots directly into the native NEXORA GTK installer.
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec bash "$ROOT_DIR/scripts/build-minimal-installer.sh" "$@"
