# Building NEXORA OS with Penguins' eggs

NEXORA OS uses **Penguins' eggs** as its live-ISO remastering engine. Debian live-build is no longer used to generate the ISO.

## Target

- Debian 13 (Trixie)
- amd64
- KDE Plasma
- Spanish (Chile) locale and Latin American keyboard layout
- Hybrid live ISO (BIOS + UEFI, as supported by the installed Eggs release)

## Important: use a dedicated build machine

Penguins' eggs remasters the **running operating system**. It does not take the old live-build package list and independently assemble a new root filesystem. Use a dedicated Debian 13 Trixie virtual machine or spare machine. The preparation script installs the full NEXORA desktop package set and copies NEXORA system defaults into that machine.

Do not run the preparation script on your everyday computer: it installs a complete desktop environment and replaces selected system configuration files.

## 1. Prepare the NEXORA build system

Clone the repository on a fresh Debian 13 Trixie amd64 installation:

~~~bash
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
sudo ./scripts/prepare-system.sh
~~~

The script installs packages from config/package-lists/nexora-desktop.list.chroot and applies the files in config/includes.chroot. It also installs the NEXORA release marker used by the build safety check.

## 2. Install Penguins' eggs

Install the current official penguins-eggs package using the upstream instructions. The official quick start is:
https://github.com/pieroproietti/penguins-eggs/blob/main/DOCS/2-user-manual/1-quickstart.md

The upstream quick start documents adding the Eggs package repository with:

~~~bash
sudo eggs tools repo add
~~~

If Eggs is not installed yet, first obtain and install its current Debian package from the official Penguins' eggs release/package instructions. Then check it:

~~~bash
sudo ./scripts/check-dependencies.sh
eggs version
~~~

## 3. Configure the ISO identity

Before the first remaster, open the Eggs configuration interface:

~~~bash
sudo eggs config
~~~

Set the ISO prefix to nexora-os, choose the desired compression, and review the live-user settings. Keep the build in **Standard Live** mode. Do not use clone mode for distributable releases because clone mode is intended to preserve the source system's user accounts and personal data.

## 4. Build

From the NEXORA OS source checkout on the configured NEXORA build system:

~~~bash
sudo ./scripts/build.sh
~~~

The ISO is placed in build-output/ and renamed to nexora-os-VERSION-ARCH.iso.

## Clean

Remove generated ISO files from this project's output directory:

~~~bash
sudo ./scripts/clean.sh
~~~

For an interrupted remaster, the clean script invokes the Eggs workspace cleanup command and removes project ISO artifacts.

## Testing

Test the generated ISO in a virtual machine before installing it on physical hardware. Check:

1. The live boot menu appears.
2. The system reaches the KDE Plasma desktop.
3. Display, keyboard and pointer work.
4. Network Manager detects available network interfaces.
5. Spanish (Chile) locale and Latin American keyboard layout are correct.
6. The NEXORA branding and installer entry points are present.

Limbo/QEMU testing should be performed with a VM configuration matching the ISO architecture. Do not treat a successful ISO build as proof that every machine is supported.

## Installer

Penguins' eggs can provide its own system installation paths, including Krill (TUI) and Calamares (GUI), depending on the installed packages. NEXORA's own installer remains a separate project component; this migration does not silently replace it. Installer integration and branding must be validated independently before release.

## Troubleshooting

- Confirm the source system is Debian 13 Trixie and has /etc/nexora-release.
- Run eggs version and eggs remaster --debug to inspect the installed Eggs version and remaster plan.
- Check the upstream Penguins' eggs documentation for release-specific dependencies and supported options.
- If a build is interrupted, run sudo ./scripts/clean.sh before retrying.
