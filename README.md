# NEXORA OS Minimal

**Your Terminal. Your Universe.**

[![Build Minimal ISO](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml/badge.svg)](https://github.com/Reaccionador2Jeje/NEXORA-OS/actions/workflows/build-iso.yml)

NEXORA OS Minimal is the terminal-only edition of NEXORA OS, based on **Debian 13 (Trixie)** for amd64. It is designed to provide a small, usable live system without a graphical desktop.

> Status: early development. The first reproducible, bootable Minimal ISO is the current milestone.

## Design goals

- Terminal-only: no X.Org, Wayland, display manager or desktop environment.
- Small package selection: APT recommends disabled and no firmware bundles.
- Debian systemd init and Debian Live boot.
- Essential shell, filesystem, process, networking and package-management tools.
- Spanish (Chile) live-session defaults.
- No browser, Flatpak, app store or preinstalled games.

## Expected image size

The first CI build will measure the actual compressed ISO. The initial engineering target is **under 500 MB**, not a guaranteed size. Kernel, initramfs, live boot infrastructure and Debian base packages impose a minimum footprint. We will set a more precise target after the first successful build.

## Build

On a Debian 13 amd64 host:

```sh
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
git checkout feature/nexora-minimal-terminal
sudo ./scripts/build.sh
```

The ISO is placed in `build-output/`; the build script prints its actual size.

## Package manifest

The package selection is maintained in `config/package-lists/nexora-minimal.list.chroot`. Keep this edition free of graphical stacks and convenience bundles. Optional applications should be installed by the user after boot.

## Editions

| Edition | Purpose | Development branch |
| --- | --- | --- |
| Minimal | Terminal-only base system | `feature/nexora-minimal-terminal` |
| XFCE | Lightweight graphical desktop | `feature/nexora-xfce-hyperlight-ci` |

## Principles

- Open source and transparent by default.
- Prefer Debian packages and upstream components.
- Keep the base system small, reproducible and maintainable.
- Measure real ISO size and validate booting before making size claims.

## License

Original project materials follow the repository license. Debian and upstream components retain their respective licenses and notices.
