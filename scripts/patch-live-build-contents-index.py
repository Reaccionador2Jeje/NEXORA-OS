#!/usr/bin/env python3
"""Patch legacy live-build Contents URLs to Debian's component index layout.

Debian Trixie publishes binary Contents indexes under dists/<suite>/main/.
Some Ubuntu runner live-build helpers still request dists/<suite>/Contents-,
which returns HTTP 404. Handle both braced and unbraced shell variables as
well as hard-coded suite names. The patch is idempotent.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

library_dir = Path(
    sys.argv[1] if len(sys.argv) > 1 else
    os.environ.get("LIVE_BUILD_LIBRARY_DIR", "/usr/lib/live/build")
)

if not library_dir.is_dir():
    raise SystemExit(f"live-build library directory not found: {library_dir}")

# Match either a shell suite variable or a literal suite name between /dists/
# and /Contents-. Avoid double-inserting /main/ on already-fixed paths.
suite = (
    r"\$\{LB_(?:PARENT_)?DISTRIBUTION\}"
    r"|\$LB_(?:PARENT_)?DISTRIBUTION"
    r"|[A-Za-z0-9._+-]+"
)
contents_path = re.compile(
    rf"(?P<prefix>/dists/)(?P<suite>{suite})(?P<suffix>/Contents-)"
)

# Debian 13 removed LILO and the old 2.6 kernel package names.
package_replacements = (
    ('DI_REQ_PACKAGES="lilo grub"', 'DI_REQ_PACKAGES="grub-pc"'),
    ('DI_REQ_PACKAGES="lilo grub-pc"', 'DI_REQ_PACKAGES="grub-pc"'),
    (
        'DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-2.6-amd64"',
        'DI_PACKAGES="${DI_REQ_PACKAGES} linux-image-amd64"',
    ),
)

patched: list[str] = []
already_compatible: list[str] = []
unfixed: list[str] = []

for path in sorted(p for p in library_dir.rglob("*") if p.is_file()):
    try:
        original = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        continue

    updated = contents_path.sub(
        lambda match: (
            f"{match.group('prefix')}{match.group('suite')}"
            f"/main{match.group('suffix')}"
        ),
        original,
    )
    for old, new in package_replacements:
        updated = updated.replace(old, new)

    if updated != original:
        path.write_text(updated, encoding="utf-8")
        patched.append(str(path))
    elif "main/Contents-" in original:
        already_compatible.append(str(path))

    for line_number, line in enumerate(updated.splitlines(), start=1):
        if contents_path.search(line):
            unfixed.append(f"{path}:{line_number}: {line.strip()}")

if unfixed:
    print("ERROR: live-build still contains legacy Contents URLs:", file=sys.stderr)
    print("\n".join(unfixed), file=sys.stderr)
    raise SystemExit(1)

if patched:
    for name in patched:
        print(f"Patched live-build helper: {name}")
elif already_compatible:
    print("live-build Contents URLs are already component-aware.")
else:
    print(
        "No legacy Contents URL was found in the live-build library; "
        "nothing needed patching."
    )
