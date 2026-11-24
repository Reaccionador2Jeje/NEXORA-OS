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

## NEXORA Minimal GTK Netinst (native installer)

The Minimal ISO now boots a dedicated Debian Live runtime built with scripts/build-minimal-installer.sh. It uses a lightweight Openbox session rather than XFCE, with LightDM auto-login for the live user and an Openbox autostart entry that launches /usr/bin/nexora-installer automatically. Users therefore arrive at the native NEXORA GTK3 wizard instead of Debian Installer.

The boot environment includes GTK3/PyGObject, NetworkManager and its connection editor, PolicyKit, rsync, partitioning and filesystem tools, GRUB BIOS/UEFI utilities, and the NEXORA installer engine. It is intentionally a small graphical environment used to install the system, not a full desktop.

The native installer offers the Minimal terminal profile or the XFCE4 profile. Minimal removes the temporary Openbox, LightDM and Xorg runtime from the installed system and boots to a text target. XFCE installs the full XFCE desktop and LightDM. Disk partitioning remains an explicit, destructive whole-disk operation after the review/confirmation screen.

The build verifies the squashfs contains the native GTK application and engine, LightDM auto-login configuration, Openbox autostart, and required runtime packages. A QEMU boot smoke test is still required; a successful ISO build alone does not prove the graphical wizard has been visually tested.

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

Both bootable editions use the shared NEXORA BIOS Syslinux and UEFI GRUB palette and splash. The Minimal ISO's boot environment starts the native NEXORA GTK wizard automatically through LightDM and Openbox; it does not boot Debian Installer or use the Debian Installer initrd banner.

The XFCE4 Live edition starts the complete NEXORA desktop and exposes the same native installer through its desktop shortcut. Both editions use the same GTK installer application and disk installation engine.
