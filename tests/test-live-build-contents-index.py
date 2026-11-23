#!/usr/bin/env python3
"""Regression tests for all live-build Debian Contents index helpers."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCHER = ROOT / "scripts" / "patch-live-build-contents-index.py"

legacy_parent = "${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/Contents-${LB_ARCHITECTURES}.gz"
legacy_mirror = "${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/Contents-${LB_ARCHITECTURES}.gz"
fixed_parent = "${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/main/Contents-${LB_ARCHITECTURES}.gz"
fixed_mirror = "${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/main/Contents-${LB_ARCHITECTURES}.gz"

with tempfile.TemporaryDirectory(prefix="nexora-live-build-test-") as tmp:
    library = Path(tmp)
    # The original workaround only changed this helper. Regression coverage
    # ensures other live-build stages receive the same correction.
    chroot_helper = library / "lb_chroot_linux-image"
    binary_helper = library / "lb_binary_debian-installer"
    chroot_helper.write_text(f"wget {legacy_parent}\n", encoding="utf-8")
    binary_helper.write_text(f"wget {legacy_mirror}\n", encoding="utf-8")

    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)
    if chroot_helper.read_text(encoding="utf-8") != f"wget {fixed_parent}\n":
        raise SystemExit("FAIL: chroot linux-image helper was not patched.")
    if binary_helper.read_text(encoding="utf-8") != f"wget {fixed_mirror}\n":
        raise SystemExit("FAIL: binary Debian Installer helper was not patched.")

    # The compatibility patch must be safe to run repeatedly.
    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)
    if chroot_helper.read_text(encoding="utf-8") != f"wget {fixed_parent}\n":
        raise SystemExit("FAIL: second patch run changed the chroot helper.")
    if binary_helper.read_text(encoding="utf-8") != f"wget {fixed_mirror}\n":
        raise SystemExit("FAIL: second patch run changed the binary helper.")

print("PASS: every live-build helper is patched and the workaround is idempotent.")
