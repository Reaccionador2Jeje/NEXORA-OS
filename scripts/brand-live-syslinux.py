#!/usr/bin/env python3
"""Apply NEXORA branding to the BIOS Syslinux/ISOLINUX menu in a Live ISO."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

MARKER = "# NEXORA OS visual identity"
CONFIG_PATHS = ("/isolinux/isolinux.cfg", "/isolinux.cfg")


def brand_syslinux_config(config: str) -> str:
    """Style the BIOS menu while retaining every upstream boot entry."""
    if MARKER in config:
        return config
    config = __import__("re").sub(
        r"(?im)^UI\s+\S+\s*$", "UI vesamenu.c32", config, count=1
    )
    if not __import__("re").search(r"(?im)^UI\s+vesamenu\.c32\s*$", config):
        config = "UI vesamenu.c32\n" + config
    style = """# NEXORA OS visual identity
MENU TITLE NEXORA OS - YOUR TERMINAL. YOUR UNIVERSE.
MENU BACKGROUND /isolinux/splash.png
MENU COLOR border       30;44   #334155 #101827
MENU COLOR title        1;36;44 #67e8f9 #101827
MENU COLOR sel          7;37;44 #ffffff #1d4ed8
MENU COLOR unsel        37;44   #dce6f2 #101827
MENU COLOR hotsel       1;37;44 #ffffff #1e40af
MENU COLOR timeout_msg  37;44   #67e8f9 #101827
MENU COLOR timeout      1;37;44 #ffffff #101827
MENU COLOR cmdline      37;40   #dce6f2 #101827
"""
    return style + config


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: brand-live-syslinux.py SOURCE.iso OUTPUT_DIR")
    iso = Path(sys.argv[1]).resolve()
    output_dir = Path(sys.argv[2]).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    upstream = output_dir / "isolinux-upstream.cfg"
    found = None
    for candidate in CONFIG_PATHS:
        result = subprocess.run(
            ["xorriso", "-osirrox", "on", "-indev", str(iso),
             "-extract", candidate, str(upstream)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode == 0 and upstream.is_file() and upstream.stat().st_size:
            found = candidate
            break
        upstream.unlink(missing_ok=True)
    if found is None:
        raise SystemExit("Could not find an ISOLINUX config in the XFCE Live ISO.")
    original = upstream.read_text(encoding="utf-8")
    if "label " not in original.lower() and "include " not in original.lower():
        raise SystemExit("The extracted ISOLINUX config has no boot labels/includes.")
    (output_dir / "isolinux.cfg").write_text(
        brand_syslinux_config(original), encoding="utf-8"
    )
    (output_dir / "isolinux-path.txt").write_text(found + "\n", encoding="utf-8")
    upstream.unlink(missing_ok=True)
    print(f"Prepared NEXORA BIOS menu at {found}.")


if __name__ == "__main__":
    main()
