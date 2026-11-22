# Installer integration

NEXORA OS Minimal uses Debian Installer GTK as its installer foundation.

The ISO build embeds two preseed profiles under `/nexora/preseed/`:

- `minimal.cfg`: standard system utilities only; no desktop environment.
- `desktop.cfg`: standard system utilities plus `xfce-desktop`.

Use the boot arguments in [BOOT-OPTIONS.md](BOOT-OPTIONS.md) to select a profile. Debian Installer remains responsible for hardware detection, networking, package installation and bootloader setup.

**Safety:** both profiles intentionally leave disk partitioning interactive. They do not define an automatic partition recipe or silently authorize formatting.

The installer interface is still Debian's upstream GTK interface. NEXORA branding, a graphical profile chooser, localization polish, and automatic NEXORA desktop theming are future milestones.
