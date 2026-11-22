# NEXORA OS Minimal — Installer Architecture

## Direction

The Minimal edition is a network installer, not a Live system. Debian Installer (d-i) with the GTK frontend is the installation framework.

## Boot media

The prototype uses Debian Trixie's official amd64 GTK netboot mini ISO from:

`https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/gtk/mini.iso`

The build process preserves its El Torito boot metadata and sets the ISO volume label to `NEXORA_MINIMAL`.

## Installation flow

1. Boot Debian Installer GTK.
2. Select language, region and keyboard.
3. Configure network and Debian mirror.
4. Partition the target disk through the installer's interactive partitioner.
5. Select software tasks:
   - Minimal: standard system utilities only.
   - Desktop: standard system utilities plus `xfce-desktop`.
6. Install GRUB and finish installation.

The installer must never preselect destructive disk partitioning. Disk layout stays interactive.

## Profile strategy

Tasksel is the first prototype's profile selector. Debian documents `standard` and `xfce-desktop` as available tasks. The custom NEXORA profile selector will replace the generic labels after the GTK netinst boot pipeline is verified.

## Next milestones

- Replace generic Debian boot menu labels and artwork with NEXORA branding.
- Add NEXORA-specific debconf/profile selection without bypassing d-i's disk safety steps.
- Package the NEXORA XFCE theme, wallpaper, Welcome and Store as a signed/local installable profile.
- Ensure Minimal never installs a graphical task by default.
- Test both profiles end-to-end in QEMU, including installed-system first boot.
