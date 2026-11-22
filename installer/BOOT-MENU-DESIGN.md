# NEXORA boot menu — implementation plan

## Goal

Provide a branded boot-time profile chooser before Debian Installer starts:

1. **NEXORA Minimal Terminal** — starts GTK Debian Installer with the Minimal preseed.
2. **NEXORA XFCE Desktop** — starts GTK Debian Installer with the XFCE preseed.
3. **Standard Debian Installer** — retains an upstream fallback entry.

## Technical approach

The current upstream GTK mini ISO is retained as the base. Before changing boot menus, CI runs `scripts/inspect-boot-layout.sh` to identify the exact Syslinux/ISOLINUX and GRUB configuration paths in the downloaded image.

The next implementation step will patch only verified bootloader configuration files, preserving the original kernel/initrd paths, boot parameters, BIOS boot catalog and UEFI boot path. The two NEXORA entries will append:

- Minimal: `priority=high preseed/file=/cdrom/nexora/preseed/minimal.cfg`
- XFCE: `auto=true priority=critical preseed/file=/cdrom/nexora/preseed/desktop.cfg`

## Safety and scope

- Profile entries choose packages only; they do not automate disk partitioning.
- The original Debian installer entry remains available as a recovery/fallback path.
- The profile menu is a bootloader menu, not a replacement GTK screen inside Debian Installer.
- No bootloader file should be rewritten based on guessed paths. The actual ISO layout must be captured by CI first.


## Interactive partitioning requirement

The profile menu must use `priority=high` with the preseed path. It must not use `auto=true priority=critical`, because that suppresses ordinary installer questions and is inappropriate for a flow that promises interactive disk setup.
