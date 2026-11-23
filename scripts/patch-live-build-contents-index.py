#!/usr/bin/env python3
"""Patch legacy live-build Debian Contents index URLs.

Debian publishes architecture Contents indexes below an archive component:
  dists/<suite>/main/Contents-<arch>.gz
Some live-build helpers still request:
  dists/<suite>/Contents-<arch>.gz

The old workaround patched only lb_chroot_linux-image. The XFCE Live build
also invokes other helpers, so scan every text helper in the live-build
library and fix every occurrence. This is intentionally idempotent.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

library_dir = Path(
    sys.argv[1] if len(sys.argv) > 1 else
    os.environ.get("LIVE_BUILD_LIBRARY_DIR", "/usr/lib/live/build")
)

if not library_dir.is_dir():
    raise SystemExit(f"live-build library directory not found: {library_dir}")

replacements = (
    (
        "${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/Contents-",
        "${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/main/Contents-",
    ),
    (
        "${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/Contents-",
        "${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/main/Contents-",
    ),
)

patched: list[str] = []
already_fixed: list[str] = []

for path in sorted(p for p in library_dir.rglob("*") if p.is_file()):
    try:
        original = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        continue

    updated = original
    for old, new in replacements:
        updated = updated.replace(old, new)

    if updated != original:
        path.write_text(updated, encoding="utf-8")
        patched.append(str(path))
    elif any(new in original for _, new in replacements):
        already_fixed.append(str(path))

if patched:
    for name in patched:
        print(f"Patched legacy live-build Contents URL: {name}")
elif already_fixed:
    print("live-build Contents URL is already fixed:")
    for name in already_fixed:
        print(f"  {name}")
else:
    print(
        "No legacy Contents URL found in the installed live-build helpers; "
        "leaving the installed package unchanged."
    )
