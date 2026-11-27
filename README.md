# NEXORA OS

**Your Terminal. Your Universe.**

[![Validate ISO project](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml)

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
- ISO builder: **Penguins' eggs**
- First milestone: reproducible bootable Desktop test ISO

## Included desktop software

The Desktop edition is being assembled with:
- **Chromium** as the default web browser for new user profiles.
- KDE utilities: Discover, System Settings, System Monitor, Ark, Okular, Gwenview, Spectacle, Filelight and more.
- Games: SuperTux, SuperTuxKart, Neverball, Chromium B.S.U. and a selection of KDE arcade and puzzle games.
- System tools: Fastfetch, htop, ncdu, rsync, tree, sensors and common archive utilities.

The initial package selection is maintained in config/package-lists/nexora-desktop.list.chroot. It remains the reference package manifest while the ISO workflow transitions to Eggs.

## Build the Desktop image

Penguins' eggs remasters the running system. Use a **dedicated Debian 13 Trixie VM**, not your everyday workstation. Prepare it with the repository script, install the official Eggs package, configure Eggs, and then build:

~~~bash
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
sudo ./scripts/prepare-system.sh
# Install the official Penguins' eggs package, then:
sudo eggs config
sudo ./scripts/build.sh
~~~

The generated image is placed in build-output/. See docs/BUILDING.md for the full setup and testing procedure.

## Repository map

- config/ — package manifest and live-system configuration reference.
- scripts/ — ISO build and maintenance helpers.
- docs/ — architecture, build guide and roadmap.
- branding/ — NEXORA logo, icon, wallpaper and visual identity guide.
- packages/ — future NEXORA OS packages and integrations.

## Development principles

- Open source and transparent by default.
- Respect Debian and upstream project licenses.
- Prefer stable, maintainable components over unnecessary complexity.
- Keep builds reproducible and document important decisions.

## License

The repository's top-level license applies to original project materials where appropriate. Components from Debian and other upstream projects retain their respective licenses and notices.
