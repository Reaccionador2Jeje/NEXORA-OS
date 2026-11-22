#!/bin/sh
# Stable entry point for the NEXORA GTK netinst builder.
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
exec sh "$ROOT_DIR/scripts/build-netinst.sh" "$@"
