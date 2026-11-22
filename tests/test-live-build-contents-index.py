#!/usr/bin/env python3
"""Regression test for the live-build Debian Contents index URL workaround."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCHER = ROOT / "scripts" / "patch-live-build-contents-index.py"

legacy = """#!/bin/sh
wget ${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/Contents-${LB_ARCHITECTURES}.gz
wget ${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/Contents-${LB_ARCHITECTURES}.gz
"""

expected = """#!/bin/sh
wget ${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/main/Contents-${LB_ARCHITECTURES}.gz
wget ${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/main/Contents-${LB_ARCHITECTURES}.gz
"""

with tempfile.TemporaryDirectory(prefix="nexora-live-build-test-") as tmp:
    library = Path(tmp)
    helper = library / "lb_chroot_linux-image"
    helper.write_text(legacy, encoding="utf-8")

    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)
    actual = helper.read_text(encoding="utf-8")
    if actual != expected:
        raise SystemExit("FAIL: the legacy live-build URL was not patched correctly.")

    # The compatibility patch must be safe to run repeatedly.
    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)
    if helper.read_text(encoding="utf-8") != expected:
        raise SystemExit("FAIL: running the patcher twice changed the result.")

print("PASS: legacy Debian Contents URLs are corrected and the patch is idempotent.")
