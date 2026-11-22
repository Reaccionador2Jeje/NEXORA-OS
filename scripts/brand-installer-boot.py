#!/usr/bin/env python3
"""Patch verified Debian Installer GRUB and Syslinux menus with NEXORA entries."""
import os
import re
import subprocess
import sys
from pathlib import Path

if len(sys.argv) != 3:
    raise SystemExit("Usage: brand-installer-boot.py SOURCE.iso OUTPUT_DIR")

iso = Path(sys.argv[1]).resolve()
out = Path(sys.argv[2]).resolve()
out.mkdir(parents=True, exist_ok=True)


def extract(iso_path: str, destination: Path) -> bool:
    result = subprocess.run(
        ["xorriso", "-osirrox", "on", "-indev", str(iso),
         "-extract", iso_path, str(destination)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0 and destination.is_file() and destination.stat().st_size > 0


# UEFI: Debian Trixie's verified path from the inspected netboot GTK image.
grub_src = out / "grub-upstream.cfg"
if not extract("/boot/grub/grub.cfg", grub_src):
    raise SystemExit("Expected UEFI GRUB config /boot/grub/grub.cfg was not found.")

grub = grub_src.read_text(encoding="utf-8")
if "NEXORA OS Minimal" not in grub:
    # Prefer the NEXORA artwork; retain Debian's original splash as fallback.
    marker = "if background_image /isolinux/splash.png; then"
    if marker not in grub:
        raise SystemExit("GRUB splash block changed; refusing an unsafe blind patch.")
    grub = grub.replace(
        marker,
        "if background_image /nexora/nexora-installer-background.png; then\n"
        "  set color_normal=light-gray/black\n"
        "  set color_highlight=white/black\n"
        "elif background_image /isolinux/splash.png; then",
        1,
    )
    entries = """menuentry 'NEXORA OS Minimal' {
    set background_color=black
    linux    /linux priority=high preseed/file=/cdrom/nexora/preseed/minimal.cfg theme=dark vga=788 --- quiet
    initrd   /initrd.gz
}
menuentry 'NEXORA OS XFCE Desktop' {
    set background_color=black
    linux    /linux priority=high preseed/file=/cdrom/nexora/preseed/desktop.cfg theme=dark vga=788 --- quiet
    initrd   /initrd.gz
}
"""
    first_entry = re.search(r"(?m)^menuentry 'Install' \{", grub)
    if not first_entry:
        raise SystemExit("GRUB upstream Install entry was not found; refusing to replace it.")
    grub = grub[:first_entry.start()] + entries + grub[first_entry.start():]

grub_out = out / "grub.cfg"
grub_out.write_text(grub, encoding="utf-8")

# BIOS: isolinux.cfg in this image includes menu.cfg from the ISO root.
menu_src = out / "menu-upstream.cfg"
if extract("/menu.cfg", menu_src):
    menu_iso_path = "/menu.cfg"
else:
    # Some Debian builds put the menu under /isolinux instead.
    menu_src = out / "isolinux-menu-upstream.cfg"
    menu_iso_path = "/isolinux/menu.cfg"
    if not extract(menu_iso_path, menu_src):
        raise SystemExit("Expected Syslinux menu.cfg was not found in either verified location.")

menu = menu_src.read_text(encoding="utf-8")
if "NEXORA OS Minimal" not in menu:
    menu = re.sub(
        r"(?m)^menu title .*$",
        "menu title NEXORA OS Installer",
        menu,
        count=1,
    )
    if "menu title NEXORA OS Installer" not in menu:
        menu = "menu title NEXORA OS Installer\n" + menu
    # vesamenu.c32 supports PNG backgrounds. Original Debian entries remain below.
    menu = "menu background /nexora/nexora-installer-background.png\n" + menu
    entries = """\
label nexora-minimal
  menu label ^NEXORA OS Minimal Terminal
  menu default
  kernel /linux
  append vga=788 initrd=/initrd.gz priority=high preseed/file=/cdrom/nexora/preseed/minimal.cfg theme=dark --- quiet

label nexora-xfce
  menu label NEXORA OS ^XFCE Desktop
  kernel /linux
  append vga=788 initrd=/initrd.gz priority=high preseed/file=/cdrom/nexora/preseed/desktop.cfg theme=dark --- quiet

"""
    # Place our choices before Debian's regular Install entry, preserving all
    # upstream rescue, expert, and fallback entries untouched.
    install = re.search(r"(?m)^label install\b", menu)
    if install:
        menu = menu[:install.start()] + entries + menu[install.start():]
    else:
        menu += "\n" + entries

menu_out = out / "menu.cfg"
menu_out.write_text(menu, encoding="utf-8")
(out / "menu-path.txt").write_text(menu_iso_path + "\n", encoding="utf-8")

print("Prepared NEXORA boot menus:")
print("  UEFI: /boot/grub/grub.cfg")
print(f"  BIOS: {menu_iso_path}")
print("  Debian upstream fallback entries preserved.")
