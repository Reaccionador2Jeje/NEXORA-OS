#!/usr/bin/env python3
"""Regression tests for legacy Debian live-build Contents URL compatibility."""
from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATCHER = ROOT / "scripts" / "patch-live-build-contents-index.py"

fixtures = {
    "lb_chroot_linux-image": (
        "wget ${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/Contents-amd64.gz\n",
        "wget ${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/main/Contents-amd64.gz\n",
    ),
    "lb_binary_debian-installer": (
        "wget $LB_MIRROR_CHROOT/dists/$LB_DISTRIBUTION/Contents-amd64.gz\n",
        "wget $LB_MIRROR_CHROOT/dists/$LB_DISTRIBUTION/main/Contents-amd64.gz\n",
    ),
    "lb_installer_literal_suite": (
        "wget https://deb.debian.org/debian/dists/trixie/Contents-amd64.gz\n",
        "wget https://deb.debian.org/debian/dists/trixie/main/Contents-amd64.gz\n",
    ),
}

legacy_packages = """#!/bin/sh
DI_REQ_PACKAGES="lilo grub"
DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-2.6-amd64"
"""
fixed_packages = """#!/bin/sh
DI_REQ_PACKAGES="grub-pc"
DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-amd64"
"""

with tempfile.TemporaryDirectory(prefix="nexora-live-build-test-") as tmp:
    library = Path(tmp)
    for name, (legacy, _) in fixtures.items():
        (library / name).write_text(legacy, encoding="utf-8")

    binary_helper = library / "lb_binary_debian-installer"
    binary_helper.write_text(
        fixtures["lb_binary_debian-installer"][0] + legacy_packages,
        encoding="utf-8",
    )

    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)

    for name, (_, expected) in fixtures.items():
        content = (library / name).read_text(encoding="utf-8")
        if name == "lb_binary_debian-installer":
            expected += fixed_packages
        if content != expected:
            raise SystemExit(f"FAIL: Contents URL or package names not fixed in {name}")

    # Re-running must not add a second /main/ component.
    subprocess.run([sys.executable, str(PATCHER), str(library)], check=True)
    for name, (_, expected) in fixtures.items():
        content = (library / name).read_text(encoding="utf-8")
        if name == "lb_binary_debian-installer":
            expected += fixed_packages
        if content != expected:
            raise SystemExit(f"FAIL: patch is not idempotent for {name}")

print(
    "PASS: braced, unbraced and literal Debian Contents URLs are fixed; "
    "package compatibility patch is idempotent."
)
