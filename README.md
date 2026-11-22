# NEXORA OS Minimal — GTK Netinst

**Your Terminal. Your Universe.**

NEXORA OS Minimal is moving from a Debian Live image to a **network installer (netinst)** based on Debian 13 Trixie for amd64.

## Installer technology

The installer foundation is Debian Installer (d-i) with its GTK graphical frontend. The build downloads Debian's official GTK netboot mini ISO and rewrites its ISO volume label to `NEXORA_MINIMAL`, preserving the upstream boot catalog.

The upstream Trixie GTK mini ISO is approximately 104 MB at the time this pipeline was designed. The resulting image size is measured by CI; no final size is promised until the artifact is built and checked.

## Installation profiles

The ISO embeds two Debian Installer preseed profiles:

| NEXORA profile | Package selection |
| --- | --- |
| Minimal Terminal | Standard system utilities only; no desktop environment. |
| NEXORA XFCE | Standard system utilities plus Debian's `xfce-desktop` task. |

Choose a profile by appending its boot argument, documented in [installer/BOOT-OPTIONS.md](installer/BOOT-OPTIONS.md). The installer still uses Debian's upstream GTK interface; a graphical NEXORA profile chooser and automatic installation of NEXORA theme, Store and desktop assets remain future work.

## Build

On a Debian or Ubuntu amd64 build host:

```sh
sudo apt update
sudo apt install -y curl xorriso qemu-system-x86
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
git checkout feature/nexora-minimal-terminal
sh ./scripts/validate-config.sh
sudo ./scripts/build.sh
```

The ISO is written to `build-output/nexora-os-minimal-netinst-amd64.iso`. The script prints its size and SHA256 checksum.

## Network requirement

Netinst downloads the installed operating system from Debian repositories. A working wired or supported wireless network connection is required during installation. The installer itself is small because it does not carry the complete installed operating system or desktop packages.

## Current implementation boundary

- Debian Installer GTK bootable mini ISO: used as the upstream installer base.
- ISO volume label: changed to NEXORA.
- BIOS/UEFI boot metadata: preserved by xorriso and checked during build.
- Profile selection: embedded Minimal and XFCE preseed files, selected through installer boot arguments.
- NEXORA-branded GTK installer screens, a graphical profile chooser and automatic desktop asset deployment: not implemented yet.
- Full interactive QEMU installation test: not yet implemented; the current QEMU step is a boot smoke test only.

## Project principles

- Terminal-only installation by default.
- Download only the packages selected by the user.
- No desktop, browser, Flatpak or games in the Minimal profile.
- Keep the ISO small and measure its real size.
- Preserve Debian and upstream licenses and notices.
