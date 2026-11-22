# Installer workspace

NEXORA OS Minimal uses Debian Installer with the GTK frontend as its netinst foundation.

- [Minimal profile guidance](profiles/minimal.md)
- [NEXORA XFCE profile guidance](profiles/desktop.md)
- [Installer architecture](../docs/ARCHITECTURE.md)

The current prototype downloads Debian's official Trixie amd64 GTK mini ISO and changes its volume label while preserving its boot metadata. The tasksel profile guidance is not yet injected into the installer; users select the profile interactively in Debian Installer.
