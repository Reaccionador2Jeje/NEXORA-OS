#!/usr/bin/env python3
"""Regression checks for NEXORA BIOS/UEFI boot-menu branding."""
from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIVE_BRANDER = ROOT / "scripts/brand-live-grub.py"
BIOS_BRANDER = ROOT / "scripts/brand-live-syslinux.py"
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

bios_spec = importlib.util.spec_from_file_location("nexora_live_syslinux", BIOS_BRANDER)
bios_module = importlib.util.module_from_spec(bios_spec)
assert bios_spec and bios_spec.loader
bios_spec.loader.exec_module(bios_module)
upstream_bios = "UI menu.c32\\nDEFAULT live\\nLABEL live\\n  KERNEL /live/vmlinuz\\n  APPEND boot=live\\n"
branded_bios = bios_module.brand_syslinux_config(upstream_bios)
for required in (
    "# NEXORA OS visual identity",
    "UI vesamenu.c32",
    "MENU BACKGROUND /isolinux/splash.png",
    "MENU COLOR sel",
    "MENU COLOR title",
):
    if required not in branded_bios:
        raise SystemExit(f"FAIL: XFCE Live BIOS branding is missing: {required}")
if "LABEL live" not in branded_bios or "APPEND boot=live" not in branded_bios:
    raise SystemExit("FAIL: BIOS branding must preserve upstream boot entries.")
if bios_module.brand_syslinux_config(branded_bios) != branded_bios:
    raise SystemExit("FAIL: BIOS Syslinux branding is not idempotent.")

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
    "brand-live-syslinux.py",
    '-map "$BOOT_BRANDING_DIR/isolinux.cfg" "$SYSLINUX_CONFIG_PATH"',
    "MENU COLOR sel",
    "-map \"$PATCHED_GRUB_CFG\" /boot/grub/grub.cfg",
    "-boot_image any replay",
    "NEXORA OS visual identity",
    "menu_color_highlight=white/blue",
):
    if required not in live_builder:
        raise SystemExit(f"FAIL: XFCE Live ISO does not install/verify branded GRUB: {required}")

minimal_builder = (ROOT / "scripts/build-minimal-installer.sh").read_text(encoding="utf-8")
for required in (
    "--debian-installer false",
    "brand-live-grub.py",
    "brand-live-syslinux.py",
    "autologin-user=nexora",
    "python3 /usr/bin/nexora-installer",
    "/live/filesystem.squashfs",
    "NEXORA OS Netinst GTK Installer",
):
    if required not in minimal_builder:
        raise SystemExit(f"FAIL: Minimal ISO is not wired to the native GTK installer: {required}")
netinst_entry = (ROOT / "scripts/build-netinst.sh").read_text(encoding="utf-8")
if "build-minimal-installer.sh" not in netinst_entry:
    raise SystemExit("FAIL: Minimal GTK ISO entry point does not delegate to the native installer build.")

print("PASS: NEXORA GRUB palette, splash, preserved boot entries and Live/netinst integration.")
