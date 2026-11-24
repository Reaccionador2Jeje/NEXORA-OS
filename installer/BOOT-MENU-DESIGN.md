# NEXORA boot menu and native installer startup

## Minimal GTK installer ISO

The Minimal ISO is built as a small Debian Live system, not as a Debian Installer netboot image. Its boot menu starts the Live kernel and initramfs. The compressed root filesystem contains the NEXORA GTK3 installer, Openbox, LightDM, NetworkManager, PolicyKit and disk/bootloader utilities.

After boot:
1. LightDM automatically signs in to the temporary NEXORA live account.
2. Openbox starts its per-user autostart.
3. The autostart starts the native NEXORA GTK wizard at /usr/bin/nexora-installer.
4. The wizard uses the NEXORA installation engine at /usr/lib/nexora-installer/install-engine.py.

The temporary Openbox/LightDM/Xorg environment is used only to run the installer. The Minimal target removes it and boots to a terminal. The XFCE target installs XFCE and selects the XFCE LightDM session. The installer requires explicit confirmation before its destructive whole-disk partitioning step.

## XFCE4 Live ISO

The XFCE4 Live ISO starts the complete NEXORA desktop. The same native GTK installer is available from the Install NEXORA OS desktop shortcut and the applications menu.

## Shared BIOS and UEFI branding

Both ISO families use the same midnight-blue and cyan NEXORA boot identity:

- UEFI GRUB loads the NEXORA splash and uses the blue selection palette.
- BIOS Syslinux/ISOLINUX uses vesamenu, the matching splash, and matching selection colors.
- The original Debian Live boot entries and ISO boot records are preserved.

The builders extract the final GRUB and Syslinux configuration from each ISO and fail validation if the NEXORA splash or palette is missing. The installed-system GRUB theme is configured separately by the native installer.

## Legacy Debian Installer branding assets

The repository retains the older Debian Installer initrd and menu branding helpers for reference and possible future use. They are not part of the current Minimal ISO boot path; the current Minimal image starts the native NEXORA GTK application directly from its own Live root filesystem.
