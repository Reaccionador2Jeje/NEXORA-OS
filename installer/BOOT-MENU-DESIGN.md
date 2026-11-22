# NEXORA boot menu — implementation plan

## Goal

Provide a branded boot-time profile chooser before Debian Installer starts:

1. **NEXORA Minimal Terminal** — starts GTK Debian Installer with the Minimal preseed.
2. **NEXORA XFCE Desktop** — starts GTK Debian Installer with the XFCE preseed.
3. **Standard Debian Installer** — retains an upstream fallback entry.

## Technical approach

The current upstream GTK mini ISO is retained as the base. Before changing boot menus, CI runs `scripts/inspect-boot-layout.sh` to identify the exact Syslinux/ISOLINUX and GRUB configuration paths in the downloaded image.

The build patches verified BIOS and UEFI bootloader configuration files, preserving upstream fallback entries and boot records. It also replaces the GTK frontend banner logo assets in the compressed initrd, including the light and dark variants, before mapping the rebuilt initrd back into the ISO. The two NEXORA entries append:

- Minimal: `priority=high preseed/file=/cdrom/nexora/preseed/minimal.cfg`
- XFCE: `priority=high preseed/file=/cdrom/nexora/preseed/desktop.cfg`

## Safety and scope

- Profile entries choose packages only; they do not automate disk partitioning.
- The original Debian installer entry remains available as a recovery/fallback path.
- The profile menu is a bootloader menu, not a replacement GTK screen inside Debian Installer.
- No bootloader file should be rewritten based on guessed paths. The actual ISO layout must be captured by CI first.


## Interactive partitioning requirement

The profile menu must use `priority=high` with the preseed path so ordinary installer questions and interactive disk setup remain available.

## GTK banner branding

The GTK installer reads its banner artwork from the `rootskel-gtk` assets in the initrd. NEXORA generates matching 800×75 light/dark PNGs and replaces the four logo paths (`logo_debian.png`, `logo_debian_dark.png`, `logo_installer.png`, `logo_installer_dark.png`) under `/usr/share/graphics`. The build verifies that these paths survive initrd repacking. The GTK workflow and dialog content remain upstream Debian Installer code; only the banner identity is replaced at this stage.


## Implemented splash branding

Both netinst and XFCE4 Live builders now generate a NEXORA aurora splash with the NEXORA OS wordmark and place it at the standard BIOS and UEFI splash paths:

- BIOS / ISOLINUX: `/isolinux/splash.png`
- UEFI / GRUB: `/boot/grub/splash.png`

The netinst builder also retains the explicit NEXORA background reference in its custom GRUB and Syslinux menu configurations. Both builders extract the resulting artwork from the ISO and compare it against the generated source, so a build fails rather than silently shipping Debian's default splash.

The XFCE4 Live desktop's **Install NEXORA OS** launcher opens a branded GTK welcome screen before starting Debian Installer Live. It explains the flow and reminds the user to review disk changes. Debian Installer's actual installation engine and its GTK screens remain upstream; the NEXORA welcome screen is the first UX improvement, not a claim that the installer has been fully forked.
