#!/usr/bin/env python3
"""Create a NEXORA-styled GRUB config for the XFCE4 Live ISO."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

MARKER = "# NEXORA OS visual identity"


def brand_grub_config(config: str) -> str:
    """Apply NEXORA colors and splash while preserving Debian boot entries."""
    if MARKER in config:
        return config
    style = """# NEXORA OS visual identity
insmod png
insmod gfxterm
set gfxmode=auto
terminal_output gfxterm
set menu_color_normal=light-gray/black
set menu_color_highlight=white/blue
set color_normal=light-gray/black
set color_highlight=white/blue
set timeout_style=menu
if background_image /boot/grub/splash.png; then
  set color_normal=light-gray/black
  set color_highlight=white/blue
fi
"""
    return style + config


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("Usage: brand-live-grub.py SOURCE.iso OUTPUT.cfg")
    iso = Path(sys.argv[1]).resolve()
    output = Path(sys.argv[2]).resolve()
    extracted = output.with_suffix(".upstream.cfg")
    result = subprocess.run(
        ["xorriso", "-osirrox", "on", "-indev", str(iso),
         "-extract", "/boot/grub/grub.cfg", str(extracted)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0 or not extracted.is_file() or extracted.stat().st_size == 0:
        raise SystemExit("Could not extract /boot/grub/grub.cfg from the XFCE Live ISO.")
    original = extracted.read_text(encoding="utf-8")
    if "menuentry" not in original and "configfile" not in original:
        raise SystemExit("The extracted GRUB config does not look like a boot menu.")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(brand_grub_config(original), encoding="utf-8")
    extracted.unlink(missing_ok=True)
    print("Prepared NEXORA-styled XFCE Live GRUB config:", output)


if __name__ == "__main__":
    main()
