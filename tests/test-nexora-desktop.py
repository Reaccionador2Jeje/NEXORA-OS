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


# Parse both distributed panel files as XML instead of relying only on grep checks.
import xml.etree.ElementTree as ET

panel_paths = [
    ROOT / "config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml",
    overlay / "etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml",
]
for panel_path in panel_paths:
    root = ET.parse(panel_path).getroot()
    assert root.tag == "channel" and root.attrib.get("name") == "xfce4-panel"
    props = {node.attrib.get("name"): node for node in root.findall("property")}
    assert props["configver"].attrib.get("value") == "2"
    panel_ids = [
        value.attrib["value"]
        for value in props["panels"].findall("value")
    ]
    assert panel_ids == ["1", "2"], (panel_path, panel_ids)

    panels = {name: props[f"panel-{name}"] for name in panel_ids}
    expected = {
        "1": ("p=12;x=0;y=0", "50"),
        "2": ("p=11;x=0;y=0", "36"),
    }
    for panel_id, (position, size) in expected.items():
        panel = panels[panel_id]
        values = {node.attrib.get("name"): node for node in panel.findall("property")}
        assert values["position"].attrib.get("value") == position, (panel_path, panel_id)
        assert values["length"].attrib.get("value") == "100", (panel_path, panel_id)
        assert values["length-adjust"].attrib.get("value") == "false", (panel_path, panel_id)
        assert values["position-locked"].attrib.get("value") == "true", (panel_path, panel_id)
        assert values["mode"].attrib.get("value") == "0", (panel_path, panel_id)
        assert values["size"].attrib.get("value") == size, (panel_path, panel_id)

    plugin_root = props["plugins"]
    plugins = {
        node.attrib.get("name"): node
        for node in plugin_root.findall("property")
    }
    assert plugins["plugin-1"].attrib.get("value") == "whiskermenu"
    assert plugins["plugin-3"].attrib.get("value") == "tasklist"
    assert plugins["plugin-8"].attrib.get("value") == "clock"

    for panel_id, required in {
        "1": {"3", "4", "5", "6", "7"},
        "2": {"1", "2", "8"},
    }.items():
        panel = panels[panel_id]
        assigned = {
            node.attrib["value"]
            for node in panel.findall("./property[@name='plugin-ids']/value")
        }
        assert assigned == required, (panel_path, panel_id, assigned)

print("PASS: both NEXORA panel XML files define fixed full-width top/bottom bars and the task switcher.")


# The configured GTK theme name must match the installed theme directory.
for settings_path in [
    ROOT / "config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml",
]:
    settings_root = ET.parse(settings_path).getroot()
    theme_name = settings_root.find("./property[@name='Net']/property[@name='ThemeName']")
    assert theme_name is not None and theme_name.attrib.get("value") == "NEXORA-Ocean"

postinstall_text = postinstall.read_text(encoding="utf-8")
assert 'value="NEXORA-Ocean"' in postinstall_text
panel_css = (overlay / "usr/share/themes/NEXORA-Ocean/gtk-3.0/gtk.css").read_text(encoding="utf-8")
assert "#XfcePanelWindow" in panel_css
assert "border-radius: 0" in panel_css
print("PASS: NEXORA GTK theme name resolves and the panel has its own full-width styling.")


# Ship a small original wallpaper collection and verify the default is installed.
wallpaper_dir = overlay / "usr/share/backgrounds/nexora"
wallpapers = [
    "nexora-default.svg",
    "nexora-aurora.svg",
    "nexora-orbit.svg",
    "nexora-grid.svg",
    "nexora-midnight.svg",
]
for wallpaper in wallpapers:
    asset = wallpaper_dir / wallpaper
    assert asset.is_file() and asset.stat().st_size > 100, asset
    ET.parse(asset)

desktop_xml = ET.parse(
    ROOT / "config/includes.chroot/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
).getroot()
default_wallpaper = desktop_xml.find(
    "./property[@name='backdrop']/property[@name='screen0']/property[@name='monitor0']/property[@name='workspace0']/property[@name='last-image']"
)
assert default_wallpaper is not None
assert default_wallpaper.attrib.get("value") == "/usr/share/backgrounds/nexora/nexora-default.svg"
installer_text = (ROOT / "scripts/install-nexora-desktop.sh").read_text(encoding="utf-8")
assert all(f'nexora/{name}' in installer_text for name in wallpapers)
print("PASS: five NEXORA wallpapers ship with the desktop installer and the default wallpaper is configured.")


# Every NEXORA desktop tool shipped in the overlay must have a valid launcher.
import json
tool_names = ["nexora-ai", "nexora-center", "nexora-store", "nexora-welcome", "nexora-updater", "nexora-installer"]
for tool in tool_names:
    path = overlay / "usr/bin" / tool
    assert path.is_file() and path.stat().st_size > 0, path
    if tool in {"nexora-ai", "nexora-center", "nexora-store", "nexora-updater", "nexora-installer"}:
        ast.parse(path.read_text(encoding="utf-8"))
    else:
        assert path.read_text(encoding="utf-8").startswith("#!/bin/sh")

tool_manifest = json.loads((overlay / "usr/share/nexora/desktop-tools.json").read_text(encoding="utf-8"))
manifest_execs = {item["exec"] for item in tool_manifest["apps"]}
assert {"nexora-ai", "nexora-center", "nexora-store", "nexora-welcome"} <= manifest_execs
catalog = json.loads((overlay / "usr/share/nexora/catalog.json").read_text(encoding="utf-8"))
assert catalog.get("schema") == 1 and len(catalog.get("applications", [])) >= 8

# Check the complete wallpaper collection, not just the default image.
wallpaper_names = [
    "nexora-default.svg", "nexora-aurora.svg", "nexora-nebula.svg",
    "nexora-horizon.svg", "nexora-minimal.svg", "nexora-orbit.svg",
    "nexora-grid.svg", "nexora-midnight.svg",
]
for wallpaper in wallpaper_names:
    asset = overlay / "usr/share/backgrounds/nexora" / wallpaper
    assert asset.is_file() and asset.stat().st_size > 100, asset
    ET.parse(asset)

wallpaper_manifest = json.loads((overlay / "usr/share/nexora/wallpapers.json").read_text(encoding="utf-8"))
assert set(wallpaper_manifest.get("wallpapers", [])) == set(wallpaper_names)
print("PASS: all eight NEXORA wallpapers and desktop tool launchers are valid.")


# The panel repair command must be shipped in both ISO and desktop-update overlays.
repair_paths = [
    overlay / "usr/bin/nexora-panel-repair",
    ROOT / "config/includes.chroot/usr/bin/nexora-panel-repair",
]
for repair_path in repair_paths:
    repair = repair_path.read_text(encoding="utf-8")
    assert repair.startswith("#!/bin/sh")
    assert "before-nexora-repair" in repair
    assert 'xfce4-panel --quit' in repair
    assert 'nohup xfce4-panel' in repair
    assert 'Run this command as your normal desktop user' in repair
postinstall_text = postinstall.read_text(encoding="utf-8")
assert "/usr/bin/nexora-panel-repair" in postinstall_text
print("PASS: NEXORA panel repair utility is shipped and enabled for ISO and desktop upgrades.")
