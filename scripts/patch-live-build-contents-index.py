#!/usr/bin/env python3
"""Patch the legacy live-build Contents index URL on Ubuntu build hosts.

Some packaged live-build versions request:
  dists/<suite>/Contents-<arch>.gz
Debian publishes this index below the archive component:
  dists/<suite>/main/Contents-<arch>.gz

Only known legacy strings are changed. Newer versions that no longer contain
these strings are left untouched.
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

candidates = sorted(path for path in library_dir.glob("*linux-image*") if path.is_file())
patched: list[str] = []
already_fixed: list[str] = []

for path in candidates:
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
        "No legacy Contents URL found in the installed live-build kernel helper; "
        "leaving the installed package unchanged."
    )
