#!/usr/bin/env python3
"""Safe unit tests for NEXORA's native installer helpers (no disk operations)."""
from __future__ import annotations

import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENGINE = ROOT / "installer/desktop-overlay/usr/lib/nexora-installer/install-engine.py"
spec = importlib.util.spec_from_file_location("nexora_install_engine", ENGINE)
module = importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)

cases = {
    "/dev/sda": "/dev/sda2",
    "/dev/nvme0n1": "/dev/nvme0n1p2",
    "/dev/mmcblk0": "/dev/mmcblk0p2",
}
for disk, expected in cases.items():
    actual = module.part_path(disk, 2)
    if actual != expected:
        raise SystemExit(f"FAIL: part_path({disk!r}, 2) -> {actual!r}, expected {expected!r}")

source = ENGINE.read_text(encoding="utf-8")
for required in ("lsblk", "MOUNTS.append", "grub-install", "mkfs.ext4", "NEXORA Live"):
    if required not in source:
        raise SystemExit(f"FAIL: installer engine is missing safety or install step: {required}")
if "debian-installer-launcher" in source:
    raise SystemExit("FAIL: native installer must not invoke Debian Installer")

gui = (ROOT / "installer/desktop-overlay/usr/bin/nexora-installer").read_text(encoding="utf-8")
for required in ("typed_path.get_text().strip()", "confirmed_path != disk", "Escribe: {disk}"):
    if required not in gui:
        raise SystemExit(f"FAIL: destructive install confirmation is missing: {required}")

for required in ("def get_storage_inventory()", "def build_storage(self)", "def refresh_storage(self)",
                 "def on_storage_selection(self, selection)", "Las particiones se muestran solo como información"):
    if required not in gui:
        raise SystemExit(f"FAIL: GTK storage inspection screen is missing: {required}")
if '["welcome", "storage", "config", "progress"]' not in gui:
    raise SystemExit("FAIL: installer navigation does not include the storage step")

print("PASS: installer partition naming, disk confirmation, storage inspection and non-destructive source checks passed.")
