# NEXORA installer profile boot options

The ISO embeds two Debian Installer preseed profiles in `/nexora/preseed/`.
They select software packages only. Disk partitioning remains interactive.

## Minimal Terminal

At the Debian Installer boot entry, append:

```text
priority=high preseed/file=/cdrom/nexora/preseed/minimal.cfg
```

Installs standard system utilities without selecting a desktop environment.

## NEXORA XFCE

Append:

```text
auto=true priority=critical preseed/file=/cdrom/nexora/preseed/desktop.cfg
```

Installs standard system utilities and Debian's `xfce-desktop` task.

## Safety and current limitations

- Neither profile defines an automatic partition recipe.
- Use `priority=high`, not unattended `auto=true priority=critical` mode, so disk setup remains an interactive part of installation.
- Review every disk and formatting confirmation before accepting it.
- A working network connection is required to download packages.
- Locale and keyboard defaults are currently US English; adjust them in the installer when needed.
- This is an interim profile mechanism. A graphical NEXORA profile chooser and localized defaults are future work.
