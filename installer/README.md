# Installer integration

NEXORA now has two separate image-building paths.

## NEXORA XFCE4 Live (main edition)

The main desktop image is built with Debian Live using `scripts/build-live.sh`. It includes XFCE4, the NEXORA desktop overlay and the native NEXORA GTK installer. The ISO disables Debian Installer in the Live build.

The Live session starts directly at XFCE so users can explore NEXORA before installing. The **Install NEXORA OS** desktop shortcut opens the custom GTK3 wizard at `/usr/bin/nexora-installer`. It detects local disks, asks for a hostname and user account, and displays a destructive-operation confirmation before calling the privileged installation engine at `/usr/lib/nexora-installer/install-engine.py`.

The initial native installer uses automatic whole-disk partitioning: GPT, an EFI System Partition when booted in UEFI mode, and an ext4 root partition. In legacy BIOS mode it creates a BIOS boot partition and ext4 root. It copies the running Live system to the target and installs GRUB. **It erases the selected disk completely**; always back up important files and verify the target disk before accepting the confirmation.

The Live image includes:
- NEXORA wallpapers and GTK themes.
- NEXORA Welcome, Store, Control Center and Updater.
- XFCE4, NetworkManager, PolicyKit, Flatpak and desktop utilities.
- The native NEXORA GTK3 installer and its disk/bootloader engine.

This is the first installer implementation. A real UEFI and BIOS virtual-machine installation test is required before calling it production-ready. The build extracts the finished squashfs and checks the native installer, engine, desktop launchers, all eight wallpapers, XFCE panel locks, default wallpaper, GTK theme and required packages. It then performs a Live boot smoke test. The netinst build separately extracts and verifies its bundled NEXORA desktop/installer payload.

## NEXORA Minimal netinst

The Minimal image continues to boot Debian Installer GTK. It embeds the `preseed/minimal.cfg` and `preseed/desktop.cfg` profiles, NEXORA boot branding, and a verified copy of the native NEXORA GTK installer, engine, desktop tools, XFCE defaults and wallpapers under `/nexora/desktop-overlay`. The native GTK app is a payload in this ISO, not a replacement for Debian Installer's active runtime; its copied-Live-system engine is launched from the XFCE4 Live session. Minimal remains terminal-focused; the XFCE preseed is retained for the separate netinst workflow.

The installer uses Chilean Spanish and the Latin American keyboard layout by default. Disk partitioning remains interactive.

## Add the desktop after a Minimal terminal installation

A machine installed with the terminal-only NEXORA Minimal profile can receive the same XFCE desktop later. From the installed system, clone the project and run:

```sh
git clone --branch feature/nexora-minimal-terminal https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
sudo sh ./scripts/install-nexora-desktop.sh install
sudo reboot
```

The script installs Debian's XFCE task and LightDM, applies the desktop overlay, backs up existing XFCE user settings, enables graphical boot and installs the `nexora-desktop` status command. It does not modify disk partitioning. The separate Desktop profile in the GTK netinst installer remains available when choosing the desktop during the initial installation.

## Installer branding

The netinst image embeds NEXORA artwork at `/nexora/branding/nexora-installer.svg` and a generated boot background. The GTK initrd banner is rebranded for the installer-based Minimal image.

The XFCE4 Live image uses a custom NEXORA aurora/wordmark splash in the standard BIOS (ISOLINUX) and UEFI (GRUB) splash locations, then starts the XFCE session. The boot menu's underlying options remain Debian Live's tested entries; the branded splash replaces the stock Debian artwork.
