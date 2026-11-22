# NEXORA OS — XFCE4 Desktop & Minimal

**Your Terminal. Your Universe.**

NEXORA OS is a Debian 13 Trixie-based operating system with two installation profiles. The main desktop edition is **NEXORA XFCE4**, a familiar XFCE desktop enhanced with NEXORA themes, wallpapers and integrated tools. NEXORA Minimal remains available for terminal-focused installations.

## Editions

NEXORA has two installation images:

| Edition | Image | Purpose |
| --- | --- | --- |
| **NEXORA OS XFCE4** | Live hybrid ISO | Main desktop edition. Boots directly into the complete NEXORA XFCE desktop and can be tried without installing. |
| **NEXORA OS Minimal** | GTK netinst ISO | Small terminal-focused installer for users who want a minimal system. |

## NEXORA XFCE4 Live

The main edition is built with Debian Live (`live-build`) on Debian 13 Trixie. It starts a complete XFCE4 session from the USB or virtual machine, with NEXORA wallpapers, four GTK themes, Welcome, Store, Control Center, Updater and the configurable NEXORA AI client.

The Live desktop includes **Install NEXORA OS**, which launches Debian Installer's Live mode. The installer copies the running Live system to the selected disk rather than downloading the desktop packages again. The desktop can be tested before installation.

The Live image defaults to Chilean Spanish and the Latin American keyboard layout. Its installer is interactive; review partitioning and disk changes carefully before confirming them.

## Minimal netinst

NEXORA Minimal remains a separate, small Debian Installer GTK network installer. It offers the terminal-focused profile and keeps disk partitioning interactive. It does not include the XFCE desktop.

## Build

On a Debian or Ubuntu amd64 build host:

```sh
sudo apt update
sudo apt install -y live-build debootstrap xorriso squashfs-tools qemu-system-x86 curl cpio gzip
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
git checkout feature/nexora-minimal-terminal
sh ./scripts/validate-config.sh

# Main edition: full XFCE4 Live ISO
sudo ./scripts/build-live.sh

# Optional: Minimal GTK netinst ISO
sudo ./scripts/build.sh
```

The Live image is written to `build-output/nexora-os-xfce4-live-amd64.iso` with a matching `.sha256` file. Minimal is written to `build-output/nexora-os-minimal-netinst-amd64.iso`.

## Release publishing

The `.github/workflows/release-xfce.yml` workflow builds the Live ISO, checks its filesystem and boot catalog, runs a QEMU boot smoke test, and publishes the ISO plus checksum to GitHub Releases. Releases are experimental until the Live desktop and installation process have been tested on real hardware.

## Project principles

- Provide a complete desktop that can be tested before installation.
- Keep NEXORA Minimal available as a separate terminal-focused option.
- Keep disk partitioning interactive and clearly confirm user choices.
- Measure image size and publish checksums for every release.
- Preserve Debian and upstream licenses and notices.
