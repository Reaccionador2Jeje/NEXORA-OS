#!/usr/bin/env python3
"""Regression checks for NEXORA BIOS/UEFI boot-menu branding."""
from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIVE_BRANDER = ROOT / "scripts/brand-live-grub.py"
spec = importlib.util.spec_from_file_location("nexora_live_grub", LIVE_BRANDER)
module = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)

upstream = """set default=0
set timeout=5
menuentry 'Debian GNU/Linux Live' {
    linux /live/vmlinuz boot=live
    initrd /live/initrd.img
}
"""
branded = module.brand_grub_config(upstream)
for required in (
    "# NEXORA OS visual identity",
    "insmod png",
    "terminal_output gfxterm",
    "menu_color_normal=light-gray/black",
    "menu_color_highlight=white/blue",
    "background_image /boot/grub/splash.png",
):
    if required not in branded:
        raise SystemExit(f"FAIL: XFCE Live GRUB branding is missing: {required}")
if "menuentry 'Debian GNU/Linux Live'" not in branded or "linux /live/vmlinuz boot=live" not in branded:
    raise SystemExit("FAIL: branding must preserve upstream Live boot entries.")
if module.brand_grub_config(branded) != branded:
    raise SystemExit("FAIL: Live GRUB branding is not idempotent.")

installer_boot = (ROOT / "scripts/brand-installer-boot.py").read_text(encoding="utf-8")
for required in (
    "set menu_color_normal=light-gray/black",
    "set menu_color_highlight=white/blue",
    "set timeout_style=menu",
    "set timeout=8",
    "MENU COLOR title",
    "MENU COLOR sel",
    "menu background /nexora/nexora-installer-background.png",
):
    if required not in installer_boot:
        raise SystemExit(f"FAIL: netinst boot menu branding is missing: {required}")

live_builder = (ROOT / "scripts/build-live.sh").read_text(encoding="utf-8")
for required in (
    "brand-live-grub.py",
    "-map \"$PATCHED_GRUB_CFG\" /boot/grub/grub.cfg",
    "-boot_image any replay",
    "NEXORA OS visual identity",
    "menu_color_highlight=white/blue",
):
    if required not in live_builder:
        raise SystemExit(f"FAIL: XFCE Live ISO does not install/verify branded GRUB: {required}")

print("PASS: NEXORA GRUB palette, splash, preserved boot entries and Live/netinst integration.")
