# NEXORA OS — XFCE4 Desktop & Minimal

**Your Terminal. Your Universe.**

NEXORA OS is a Debian 13 Trixie-based operating system with two installation profiles. The main desktop edition is **NEXORA XFCE4**, a familiar XFCE desktop enhanced with NEXORA themes, wallpapers and integrated tools. NEXORA Minimal remains available for terminal-focused installations.

## Installer technology

The installer foundation is Debian Installer (d-i) with its GTK graphical frontend. The build downloads Debian's official GTK netboot mini ISO and rewrites its ISO volume label to `NEXORA_MINIMAL` or `NEXORA_XFCE`, depending on the selected edition, while preserving the upstream boot catalog.

The upstream Trixie GTK mini ISO is approximately 104 MB at the time this pipeline was designed. The resulting image size is measured by CI; no final size is promised until the artifact is built and checked.

## Installation profiles

The ISO embeds two Debian Installer preseed profiles:

| NEXORA profile | Package selection |
| --- | --- |
| Minimal Terminal | Standard system utilities only; no desktop environment. |
| NEXORA XFCE | Standard system utilities plus Debian's `xfce-desktop` task. |

Choose a profile by appending its boot argument, documented in [installer/BOOT-OPTIONS.md](installer/BOOT-OPTIONS.md). The desktop profile embeds NEXORA themes, wallpapers, NEXORA Welcome, Store, Control Center, Updater and an AI client. The installer itself uses Debian Installer GTK with NEXORA boot artwork and a profile selector; its underlying installation screens remain Debian components.

## NEXORA XFCE desktop

The desktop profile embeds five wallpapers, four GTK themes, NEXORA Welcome, Store, Control Center, Updater and the NEXORA AI client. See [installer integration](installer/README.md) and [NEXORA AI configuration](docs/AI-INTEGRATION.md). The AI client connects to a local Ollama-compatible server or another OpenAI-compatible endpoint; model weights and provider credentials are not bundled.

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
# Build the main XFCE4 desktop edition:
sudo env NEXORA_EDITION=xfce ./scripts/build.sh
```

The Minimal ISO is written to `build-output/nexora-os-minimal-netinst-amd64.iso`. The XFCE4 ISO is written to `build-output/nexora-os-xfce4-netinst-amd64.iso`. Both scripts print the image size and SHA256 checksum. The XFCE4 release workflow also runs a QEMU boot smoke test and publishes the ISO plus checksum to GitHub Releases.

## Network requirement

Netinst downloads the installed operating system from Debian repositories. A working wired or supported wireless network connection is required during installation. The installer itself is small because it does not carry the complete installed operating system or desktop packages.

## Current implementation boundary

- Debian Installer GTK bootable mini ISO: used as the upstream installer base.
- ISO volume label: changed to NEXORA.
- BIOS/UEFI boot metadata: preserved by xorriso and checked during build.
- Profile selection: embedded Minimal and XFCE preseed files, selected through installer boot arguments.
- Branded BIOS/UEFI boot menu: offers Minimal and XFCE Desktop profiles while preserving Debian fallback entries.
- XFCE4 release build: dedicated image target selects the XFCE profile by default and includes the NEXORA desktop overlay.
- Release publication: `.github/workflows/release-xfce.yml` builds, smoke-tests and publishes the ISO and SHA256 file when manually dispatched or when a `v*` tag is pushed.
- Full interactive QEMU installation test: not yet implemented; the current QEMU step is a boot smoke test only.

## Project principles

- Terminal-only installation by default.
- Download only the packages selected by the user.
- No desktop, browser, Flatpak or games in the Minimal profile.
- Keep the ISO small and measure its real size.
- Preserve Debian and upstream licenses and notices.
