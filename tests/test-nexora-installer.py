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
if '["welcome", "storage", "config", "review", "progress"]' not in gui:
    raise SystemExit("FAIL: installer navigation does not include review and progress steps")
for required in ("def build_review(self):", "def update_review(self):",
                 "Revisión final", "self.show_page(4)",
                 '"desktop": "XFCE4"', '"network": "NetworkManager'):
    if required not in gui:
        raise SystemExit(f"FAIL: final configuration review is missing: {required}")
review_section = gui.split("    def build_review(self):", 1)[1].split("    def build_progress(self):", 1)[0]
if "self.password" in review_section or "root_password" in review_section:
    raise SystemExit("FAIL: final review must never display account passwords")


# Manual partition planning is validated against a read-only lsblk-shaped
# inventory. These checks do not execute disk commands.
inventory = {"blockdevices": [{
    "name": "sda", "type": "disk", "children": [
        {"name": "sda1", "type": "part", "size": 536870912,
         "fstype": "vfat", "mountpoints": []},
        {"name": "sda2", "type": "part", "size": 20000000000,
         "fstype": None, "mountpoints": []},
    ],
}]}
valid_plan = module.validate_manual_partition_plan(
    "/dev/sda", "/dev/sda2", "/dev/sda1", inventory
)
if valid_plan is not None:
    raise SystemExit(f"FAIL: valid manual partition plan rejected: {valid_plan}")
checks = [
    ("/dev/sdb", "/dev/sda2", "/dev/sda1", "disco seleccionado"),
    ("/dev/sda", "/dev/sda1", "/dev/sda1", "deben ser distintas"),
    ("/dev/sda", "/dev/sda2", "/dev/sdb1", "mismo disco"),
]
for disk, root, efi, expected in checks:
    error = module.validate_manual_partition_plan(disk, root, efi, inventory)
    if not error or expected not in error:
        raise SystemExit(f"FAIL: unsafe plan was not rejected correctly: {error!r}")
small_inventory = {"blockdevices": [{
    "name": "sda", "type": "disk", "children": [
        {"name": "sda2", "type": "part", "size": 1024,
         "fstype": None, "mountpoints": []},
    ],
}]}
small_error = module.validate_manual_partition_plan(
    "/dev/sda", "/dev/sda2", None, small_inventory
)
if not small_error or "8 GB" not in small_error:
    raise SystemExit("FAIL: undersized root partition was accepted")


for required in ("locale_code", "timezone", "keyboard_layout", "allowed_locales",
                 "allowed_timezones", "allowed_keyboards", "locale-gen",
                 "/etc/default/keyboard", "/etc/default/locale"):
    if required not in source:
        raise SystemExit(f"FAIL: installer regional configuration is missing: {required}")
for required in ("self.locale_combo", "self.keyboard_combo", "self.timezone_combo",
                 "Español (Chile)", "Latinoamericano", "America/Santiago"):
    if required not in gui:
        raise SystemExit(f"FAIL: GTK configuration selector is missing: {required}")
if 'command = ["pkexec", ENGINE, disk, username, hostname, self.secret_path]' in gui:
    raise SystemExit("FAIL: GUI still uses the old installer engine argument list")


for required in (
    'root_enabled not in {"yes", "no"}',
    'supported_locales = (',
    '"es_CL.UTF-8", "es_ES.UTF-8", "en_US.UTF-8"',
    '"en_GB.UTF-8", "pt_BR.UTF-8"',
    'locale-gen',
    'input_text="root:" + root_password',
    'passwd", "-l", "root"',
):
    if required not in source:
        raise SystemExit(f"FAIL: superuser or multilingual locale support missing: {required}")
for required in (
    "self.root_enabled = Gtk.CheckButton",
    "self.root_password",
    "self.root_password2",
    "on_root_toggle",
    "La contraseña de root debe coincidir",
    '"yes" if root_enabled else "no"',
    "config_scroll = Gtk.ScrolledWindow()",
):
    if required not in gui:
        raise SystemExit(f"FAIL: GTK superuser/configuration control missing: {required}")


for required in (
    'desktop_profile not in {"xfce", "minimal"}',
    'apt_mirror',
    'nmcli',
    'urllib.request.urlopen',
    'apt-get", "update',
    'task-xfce-desktop',
    '"multi-user.target"',
    '"graphical.target"',
    'NetworkManager',
):
    if required not in source:
        raise SystemExit(f"FAIL: APT, network or desktop profile support missing: {required}")
for required in (
    'self.desktop_combo',
    '"NEXORA XFCE4 (escritorio completo)"',
    '"NEXORA Minimal (solo sistema base)"',
    'self.apt_mirror',
    'self.refresh_network_status',
    'Comprobar conexión',
    'desktop, apt_mirror',
):
    if required not in gui:
        raise SystemExit(f"FAIL: GTK APT/network/desktop controls missing: {required}")

print("PASS: installer storage safety, account setup, multilingual locales, root account controls, regional configuration and final review checks passed.")
