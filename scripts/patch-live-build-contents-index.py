#!/usr/bin/env python3
"""Apply compatibility fixes to legacy Debian live-build helpers.

The Ubuntu runner's live-build package can contain an older
lb_binary_debian-installer helper. Its Debian Installer package list still
references removed Debian packages (lilo, grub, linux-image-2.6-amd64).
For Debian 13 amd64, use grub-pc and linux-image-amd64 instead.

Older helpers may also request Contents indexes outside the archive
component. Debian publishes these under dists/<suite>/main/.
All transformations are idempotent and limited to the installed helper
scripts; the generated NEXORA system remains based on Debian Trixie.
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
    # Debian archive Contents index layout.
    (
        "${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/Contents-",
        "${LB_PARENT_MIRROR_CHROOT}/dists/${LB_PARENT_DISTRIBUTION}/main/Contents-",
    ),
    (
        "${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/Contents-",
        "${LB_MIRROR_CHROOT}/dists/${LB_DISTRIBUTION}/main/Contents-",
    ),
    # Debian 13 removed LILO and the old 2.6 kernel package names.
    ('DI_REQ_PACKAGES="lilo grub"', 'DI_REQ_PACKAGES="grub-pc"'),
    ('DI_REQ_PACKAGES="lilo grub-pc"', 'DI_REQ_PACKAGES="grub-pc"'),
    ('DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-2.6-amd64"', 'DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-amd64"'),
)

patched: list[str] = []
already_compatible: list[str] = []

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
    elif (
        "DI_REQ_PACKAGES=\"grub-pc\"" in original
        or "main/Contents-" in original
    ):
        already_compatible.append(str(path))

if patched:
    for name in patched:
        print(f"Patched legacy live-build helper: {name}")
elif already_compatible:
    print("live-build helpers already contain the compatibility fixes:")
    for name in already_compatible:
        print(f"  {name}")
else:
    print(
        "No matching legacy live-build helper patterns found; "
        "installed helpers were left unchanged."
    )
