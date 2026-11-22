# NEXORA OS

**Your Terminal. Your Universe.**

[![Build ISO](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml)

NEXORA OS is an open-source Linux distribution based on **Debian 13 (Trixie)**. This development branch builds the **NEXORA OS 0.2.0 Hyper Lightweight XFCE4 Live** edition: a deliberately small desktop with NEXORA branding and a curated software store.

> **Project status:** experimental development. A successful reproducible ISO build and boot test are still required before this edition can be considered ready for general installation.

## What makes this edition NEXORA?

- A Debian 13 foundation, with the upstream base and package licenses respected.
- A lightweight **XFCE4** desktop configured with NEXORA defaults.
- NEXORA GTK theme, wallpaper, LightDM greeter branding and desktop panel settings.
- **NEXORA Store**, a GTK application for browsing a curated Flatpak catalog.
- A custom **Fastfetch** profile with original NEXORA ASCII branding and live system information.
- Flatpak with the Flathub remote configured; applications are downloaded only when the user chooses to install them.
- Chromium as the preinstalled browser.
- Spanish (Chile) locale and Latin American keyboard defaults.
- No preinstalled game bundles or heavyweight desktop suites.

NEXORA is more than a wallpaper applied to Debian: this branch maintains its own live-build configuration, desktop defaults, branding, welcome utility, curated store and validation scripts. It remains transparently based on Debian.

## Edition and target

| Item | Current target |
| --- | --- |
| Edition | Hyper Lightweight XFCE4 Live |
| Version | 0.2.0 |
| Base | Debian GNU/Linux 13 (Trixie) |
| Architecture | amd64 |
| Desktop | XFCE4 |
| Display manager | LightDM GTK Greeter |
| Browser | Chromium |
| App delivery | APT base + optional Flatpak apps from Flathub |
| Default locale | Spanish (Chile), with English available |
| Init system | systemd |
| ISO builder | Debian live-build |

The separate Minimal GTK Netinst work is not the same image as this XFCE4 Live branch.

## NEXORA Aurora boot theme

The XFCE Live image includes **NEXORA Aurora**, an original lightweight Plymouth script theme. It uses a deep blue gradient, a centered NEXORA wordmark, a subtle cyan animated loading ring and a short Spanish status line. The theme is selected during the chroot hook and its configuration is rebuilt into the initramfs.

The kernel command line enables `quiet splash` so the graphical boot screen can replace most routine boot messages. Hardware and firmware support varies; if a graphics driver cannot provide Plymouth's graphical renderer, the system may fall back to text-mode boot output.

## NEXORA Store

NEXORA Store presents a curated catalog with categories and search. It can install, remove and update optional Flatpak applications after administrator authentication.

The catalog currently includes options such as LibreOffice, Firefox, GIMP, Inkscape, Krita, Blender, Godot Engine, VLC, Audacity, SuperTuxKart, SuperTux and Flatseal.

These apps are **not bundled into the base ISO**. They are fetched from Flathub only when selected. Availability depends on Flathub and the target machine's architecture.

## NEXORA Upgrade Assistant

The ISO includes an experimental, read-only **NEXORA Upgrade Assistant**. It reports the installed NEXORA version, Debian base, architecture and an APT package-upgrade simulation. It is intended as the first preflight layer for a future release migration system.

Run it from the applications menu (**NEXORA Upgrade Assistant**) or with:

```bash
python3 /usr/lib/nexora/nexora-upgrade.py
```

**Important:** this prototype does not migrate between NEXORA releases, change APT repositories, or install/remove packages. Its APT check is simulation-only. Do not treat it as a substitute for backups or a supported distribution upgrade path. Full release upgrades will only be enabled after signed release metadata, compatibility rules, configuration migrations, rollback/recovery and real upgrade tests exist.

## Build the ISO

Build on a Debian 13 amd64 host with a reliable internet connection and several gigabytes of free disk space.

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso

git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS

chmod +x auto/config scripts/*.sh config/hooks/normal/*.hook.chroot
sudo ./scripts/check-dependencies.sh
sh ./scripts/validate-config.sh
sudo ./scripts/build.sh
```

The generated ISO is moved to `build-output/`. The first build downloads Debian packages and may take some time.

For full requirements, cleanup instructions and test guidance, see [docs/BUILDING.md](docs/BUILDING.md).

## Quality checks

The repository includes checks for:

- Required live-build configuration and desktop files.
- Debian Trixie, amd64 and systemd settings.
- XFCE packages and the absence of KDE/game bundles from the base image.
- NEXORA release identity, locale, greeter and desktop defaults.
- NEXORA Store Python syntax and catalog JSON.
- Fastfetch configuration JSON and NEXORA logo asset.
- Flatpak application IDs, categories and duplicate entries.

GitHub Actions builds the ISO and attempts a BIOS boot test in QEMU. A passing static validation alone does not prove that an ISO builds or boots. UEFI and physical hardware testing remain separate release tasks.

## Repository map

- `auto/` — live-build configuration entrypoint.
- `config/` — package lists, desktop defaults, hooks and included system files.
- `scripts/` — build, cleanup, dependency and validation tools.
- `docs/` — build instructions and roadmap.
- `branding/` — NEXORA logo and visual identity assets.
- `packages/` — future native NEXORA packages and integrations.

## Development principles

- Open source and transparent by default.
- Respect Debian and upstream project licenses.
- Prefer stable, maintainable components over unnecessary complexity.
- Keep builds reproducible and document important decisions.
- Do not promise performance or hardware compatibility without measurements.

## License

The repository's top-level license applies to original project materials where appropriate. Debian and other upstream components retain their respective licenses and notices.
