#!/usr/bin/env python3
"""Static regression checks for NEXORA desktop integration."""
from pathlib import Path
import ast
import configparser

ROOT = Path(__file__).resolve().parents[1]
overlay = ROOT / "installer/desktop-overlay"
updater = overlay / "usr/bin/nexora-updater"
desktop = overlay / "usr/share/applications/nexora-updater.desktop"
postinstall = overlay / "usr/local/sbin/nexora-postinstall"

ast.parse(updater.read_text(encoding="utf-8"))
assert "pkexec" in updater.read_text(encoding="utf-8")
assert '"upgrade"' in updater.read_text(encoding="utf-8")
assert '"dist-upgrade"' not in updater.read_text(encoding="utf-8")
assert '"autoremove"' not in updater.read_text(encoding="utf-8")
assert "shell=True" not in updater.read_text(encoding="utf-8")

entry = configparser.ConfigParser(interpolation=None)
entry.read(desktop, encoding="utf-8")
assert entry["Desktop Entry"]["Exec"] == "nexora-updater"
assert entry["Desktop Entry"]["Terminal"].lower() == "false"

hook = postinstall.read_text(encoding="utf-8")
assert "Based on Debian GNU/Linux 13 (Trixie)" in hook
assert "/etc/os-release" not in hook
assert "/etc/nexora-release" in hook
assert "xfce4-desktop.xml" in hook
print("PASS: NEXORA updater and desktop identity integration checks.")
