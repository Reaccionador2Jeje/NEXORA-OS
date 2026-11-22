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
