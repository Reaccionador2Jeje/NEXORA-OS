# NEXORA OS

**Your Terminal. Your Universe.**

[![Build ISO](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml)

NEXORA OS is an open-source Linux distribution based on **Debian 13 (Trixie)**, designed around a clean KDE Plasma desktop and the NEXORA ecosystem.

> Project status: early development — the first bootable test image is the current milestone.

## Vision

NEXORA OS aims to be more than a themed Debian installation. It will bring together:
- A carefully configured Debian foundation.
- KDE Plasma as the main desktop environment.
- NEXORA tools and terminal integration.
- Consistent visual identity, boot experience and system defaults.
- Transparent, reproducible build scripts.

## Planned editions

| Edition | Purpose | Status |
| --- | --- | --- |
| Desktop | General-purpose KDE Plasma workstation | In development |
| Server | Lightweight server environment | Planned |
| Core | Minimal base for custom systems | Planned |

## Current target

- Base: Debian 13 Trixie
- Architecture: amd64
- Desktop: KDE Plasma
- Languages: Spanish (Chile) and English
- ISO builder: Debian live-build
- First milestone: reproducible bootable Desktop test ISO

## Build the Desktop image

Build on a Debian 13 amd64 host or a compatible Debian 13 build environment.

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
sudo ./scripts/build.sh
```

The generated image will be placed in the repository's `build-output/` directory.

For full instructions and build requirements, see [docs/BUILDING.md](docs/BUILDING.md).

## Repository map

- `auto/` — reproducible live-build configuration entrypoint.
- `config/` — package lists and live-build settings.
- `scripts/` — build and maintenance helpers.
- `docs/` — architecture, build guide and roadmap.
- `branding/` — visual identity documentation and planned artwork, wallpapers and boot theme.
- `config/includes.chroot/` — NEXORA release identity and live-system welcome messages.
- `packages/` — future NEXORA OS packages and integrations.

## Development principles

- Open source and transparent by default.
- Respect Debian and upstream project licenses.
- Prefer stable, maintainable components over unnecessary complexity.
- Keep builds reproducible and document important decisions.

## License

The repository's top-level license applies to original project materials where appropriate. Components from Debian and other upstream projects retain their respective licenses and notices.
