#!/usr/bin/env python3
"""Regression tests for legacy Debian live-build helper compatibility."""
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

legacy_installer = """#!/bin/sh
DI_REQ_PACKAGES="lilo grub"
DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-2.6-amd64"
"""
fixed_installer = """#!/bin/sh
DI_REQ_PACKAGES="grub-pc"
DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-amd64"
"""

with tempfile.TemporaryDirectory(prefix="nexora-live-build-test-") as tmp:
    library = Path(tmp)
    chroot_helper = library / "lb_chroot_linux-image"
    binary_helper = library / "lb_binary_debian-installer"
    chroot_helper.write_text(f"wget {legacy_parent}\n", encoding="utf-8")
    binary_helper.write_text(
        f"wget {legacy_mirror}\n" + legacy_installer,
        encoding="utf-8",
    )

    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)

    if chroot_helper.read_text(encoding="utf-8") != f"wget {fixed_parent}\n":
        raise SystemExit("FAIL: chroot Contents URL was not patched.")

    expected_binary = f"wget {fixed_mirror}\n" + fixed_installer
    if binary_helper.read_text(encoding="utf-8") != expected_binary:
        raise SystemExit(
            "FAIL: Debian Installer helper still contains obsolete "
            "bootloader or kernel package names."
        )

    # The patch must be safe to run more than once.
    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)
    if chroot_helper.read_text(encoding="utf-8") != f"wget {fixed_parent}\n":
        raise SystemExit("FAIL: second patch run changed the chroot helper.")
    if binary_helper.read_text(encoding="utf-8") != expected_binary:
        raise SystemExit("FAIL: second patch run changed the installer helper.")

print(
    "PASS: Contents URLs and Debian Installer package names are compatible; "
    "the patch is idempotent."
)
