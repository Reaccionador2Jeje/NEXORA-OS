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

print("PASS: installer partition naming and non-destructive source checks passed.")
