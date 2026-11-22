#!/usr/bin/env python3
"""Replace Debian Installer GTK banner assets inside the netboot initrd."""
import gzip
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

if len(sys.argv) != 5:
    raise SystemExit("Usage: brand-installer-initrd.py SOURCE.iso OUTPUT_DIR LIGHT.png DARK.png")

source_iso = Path(sys.argv[1]).resolve()
output_dir = Path(sys.argv[2]).resolve()
light_logo = Path(sys.argv[3]).resolve()
dark_logo = Path(sys.argv[4]).resolve()
output_dir.mkdir(parents=True, exist_ok=True)
source_initrd = output_dir / "initrd-upstream.gz"
output_initrd = output_dir / "initrd-nexora.gz"

extract = subprocess.run(
    ["xorriso", "-osirrox", "on", "-indev", str(source_iso),
     "-extract", "/initrd.gz", str(source_initrd)],
    stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True,
)
if extract.returncode or not source_initrd.is_file():
    raise SystemExit("Could not extract /initrd.gz from the Debian GTK mini ISO.")

required = {
    "usr/share/graphics/logo_debian.png": light_logo,
    "usr/share/graphics/logo_debian_dark.png": dark_logo,
    "usr/share/graphics/logo_installer.png": light_logo,
    "usr/share/graphics/logo_installer_dark.png": dark_logo,
}

with tempfile.TemporaryDirectory(prefix="nexora-initrd-") as temp:
    root = Path(temp)
    listing = subprocess.run(
        ["sh", "-c", 'gzip -dc "$1" | cpio -t', "nexora", str(source_initrd)],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if listing.returncode:
        raise SystemExit("The Debian initrd is not a readable gzip-compressed cpio archive.")
    available = {line.removeprefix("./") for line in listing.stdout.splitlines()}
    missing = sorted(set(required) - available)
    if missing:
        raise SystemExit("Expected GTK logo assets are missing from initrd: " + ", ".join(missing))

    unpack = subprocess.run(
        ["sh", "-c", 'gzip -dc "$1" | cpio -idm --quiet --no-absolute-filenames',
         "nexora", str(source_initrd)],
        cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if unpack.returncode:
        raise SystemExit("Could not unpack Debian Installer initrd.")

    for relative, replacement in required.items():
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.is_symlink() or target.exists():
            target.unlink()
        shutil.copyfile(replacement, target)
        # Ensure every GTK theme variant is a real NEXORA asset, not a Debian symlink.
        if target.stat().st_size < 100:
            raise SystemExit(f"Generated logo is unexpectedly small: {relative}")

    repack = subprocess.run(
        ["sh", "-c", 'find . -print0 | cpio --null -o -H newc --quiet | gzip -9 > "$1"',
         "nexora", str(output_initrd)],
        cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    if repack.returncode or not output_initrd.is_file() or output_initrd.stat().st_size == 0:
        raise SystemExit("Could not rebuild the NEXORA GTK initrd.")

    with gzip.open(output_initrd, "rb") as stream:
        if stream.read(6) != b"070701":
            raise SystemExit("Rebuilt initrd does not contain a valid newc cpio archive.")
    verify = subprocess.run(
        ["sh", "-c", 'gzip -dc "$1" | cpio -t', "nexora", str(output_initrd)],
        text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    verified_paths = {line.removeprefix("./") for line in verify.stdout.splitlines()}
    if verify.returncode or not set(required).issubset(verified_paths):
        raise SystemExit("NEXORA GTK logos did not survive initrd repacking.")

print(f"Created branded GTK initrd: {output_initrd}")
print("Replaced Debian GTK logo variants with NEXORA branding:")
for path in required:
    print(f"  /{path}")
