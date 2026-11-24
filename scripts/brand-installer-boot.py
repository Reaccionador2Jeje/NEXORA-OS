#!/usr/bin/env python3
"""Patch Debian Installer BIOS/UEFI menus with NEXORA branding and background."""
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
default_profile = os.environ.get("NEXORA_DEFAULT_PROFILE", "minimal").lower()
if default_profile not in {"minimal", "xfce"}:
    raise SystemExit("NEXORA_DEFAULT_PROFILE must be minimal or xfce")


def extract(iso_path: str, destination: Path) -> bool:
    result = subprocess.run(
        ["xorriso", "-osirrox", "on", "-indev", str(iso),
         "-extract", iso_path, str(destination)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0 and destination.is_file() and destination.stat().st_size > 0


# UEFI GRUB: explicitly load PNG/gfxterm support before selecting NEXORA artwork.
grub_src = out / "grub-upstream.cfg"
if not extract("/boot/grub/grub.cfg", grub_src):
    raise SystemExit("Expected UEFI GRUB config /boot/grub/grub.cfg was not found.")

grub = grub_src.read_text(encoding="utf-8")
if default_profile == "xfce":
    if re.search(r"(?m)^set default=.*$", grub):
        grub = re.sub(r"(?m)^set default=.*$", "set default='NEXORA OS XFCE Desktop'", grub, count=1)
    else:
        grub = "set default='NEXORA OS XFCE Desktop'\n" + grub
if "NEXORA OS Minimal" not in grub:
    marker = "if background_image /isolinux/splash.png; then"
    if marker not in grub:
        raise SystemExit("GRUB splash block changed; refusing an unsafe blind patch.")
    grub = grub.replace(
        marker,
        "# NEXORA OS visual identity\n"
        "insmod png\ninsmod gfxterm\nset gfxmode=auto\nterminal_output gfxterm\n"
        "set menu_color_normal=light-gray/black\n"
        "set menu_color_highlight=white/blue\n"
        "set color_normal=light-gray/black\n"
        "set color_highlight=white/blue\n"
        "set timeout_style=menu\n"
        "set timeout=8\n"
        "if background_image /nexora/nexora-installer-background.png; then\n"
        "  set color_normal=light-gray/black\n"
        "  set color_highlight=white/blue\n"
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

# BIOS Syslinux: vesamenu.c32 is required for the PNG menu background directive.
menu_src = out / "menu-upstream.cfg"
if extract("/menu.cfg", menu_src):
    menu_iso_path = "/menu.cfg"
else:
    menu_src = out / "isolinux-menu-upstream.cfg"
    menu_iso_path = "/isolinux/menu.cfg"
    if not extract(menu_iso_path, menu_src):
        raise SystemExit("Expected Syslinux menu.cfg was not found in either verified location.")

menu = menu_src.read_text(encoding="utf-8")
if "NEXORA OS Minimal" not in menu:
    menu = re.sub(r"(?m)^menu title .*$", "menu title NEXORA OS Installer", menu, count=1)
    if "menu title NEXORA OS Installer" not in menu:
        menu = "menu title NEXORA OS Installer\n" + menu
    bios_style = (
        "MENU COLOR border       30;44   #334155 #101827\n"
        "MENU COLOR title        1;36;44 #67e8f9 #101827\n"
        "MENU COLOR sel          7;37;44 #ffffff #1d4ed8\n"
        "MENU COLOR unsel        37;44  #dce6f2 #101827\n"
        "MENU COLOR hotsel       1;37;44 #ffffff #1e40af\n"
        "MENU COLOR timeout_msg  37;44  #67e8f9 #101827\n"
        "MENU COLOR timeout      1;37;44 #ffffff #101827\n"
        "MENU COLOR cmdline      37;40  #dce6f2 #101827\n"
    )
    if "MENU COLOR sel" not in menu:
        menu = bios_style + menu
    menu = "menu background /nexora/nexora-installer-background.png\n" + menu
    entries = """\
label nexora-minimal
  menu label ^NEXORA OS Minimal Terminal
  kernel /linux
  append vga=788 initrd=/initrd.gz priority=high preseed/file=/cdrom/nexora/preseed/minimal.cfg theme=dark --- quiet

label nexora-xfce
  menu label NEXORA OS ^XFCE Desktop
  kernel /linux
  append vga=788 initrd=/initrd.gz priority=high preseed/file=/cdrom/nexora/preseed/desktop.cfg theme=dark --- quiet

"""
    if default_profile == "minimal":
        entries = entries.replace("  menu label ^NEXORA OS Minimal Terminal\n", "  menu label ^NEXORA OS Minimal Terminal\n  menu default\n")
    else:
        entries = entries.replace("  menu label NEXORA OS ^XFCE Desktop\n", "  menu label NEXORA OS ^XFCE Desktop\n  menu default\n")
    install = re.search(r"(?m)^label install\b", menu)
    if install:
        menu = menu[:install.start()] + entries + menu[install.start():]
    else:
        menu += "\n" + entries

menu_out = out / "menu.cfg"
menu_out.write_text(menu, encoding="utf-8")
(out / "menu-path.txt").write_text(menu_iso_path + "\n", encoding="utf-8")

# Ensure BIOS actually invokes the graphics-capable Syslinux menu renderer.
isolinux_candidates = (
    "/isolinux.cfg",
    "/isolinux/isolinux.cfg",
    "/syslinux.cfg",
    "/syslinux/syslinux.cfg",
    "/boot/isolinux/isolinux.cfg",
)
isolinux_src = out / "isolinux-upstream.cfg"
isolinux_iso_path = next(
    (candidate for candidate in isolinux_candidates if extract(candidate, isolinux_src)),
    None,
)
if isolinux_iso_path is None:
    raise SystemExit(
        "No supported BIOS Syslinux config was found. Checked: "
        + ", ".join(isolinux_candidates)
    )
isolinux = isolinux_src.read_text(encoding="utf-8")
if not re.search(r"(?im)^UI\s+vesamenu\.c32\s*$", isolinux):
    if re.search(r"(?im)^UI\s+\S+\s*$", isolinux):
        isolinux = re.sub(r"(?im)^UI\s+\S+\s*$", "UI vesamenu.c32", isolinux, count=1)
    else:
        isolinux = "UI vesamenu.c32\n" + isolinux
(out / "isolinux.cfg").write_text(isolinux, encoding="utf-8")
(out / "isolinux-path.txt").write_text(isolinux_iso_path + "\n", encoding="utf-8")

print("Prepared NEXORA boot menus:")
print("  UEFI: /boot/grub/grub.cfg (PNG module + NEXORA background)")
print(f"  BIOS: {isolinux_iso_path} + {menu_iso_path} (vesamenu.c32 + NEXORA background)")
print("  Debian upstream fallback entries preserved.")
