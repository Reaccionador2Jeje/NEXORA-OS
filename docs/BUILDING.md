# Building NEXORA OS with Penguins' eggs

NEXORA OS uses **Penguins' eggs** as its live-ISO remastering engine. The project no longer uses Debian live-build as its ISO generator.

## Target

- Debian 13 (Trixie)
- amd64
- KDE Plasma
- Spanish (Chile) locale and Latin American keyboard layout
- Hybrid live ISO (BIOS + UEFI, as supported by the installed Eggs release)

## Important: build from a dedicated NEXORA system

Penguins' eggs remasters the **running operating system**. It does not take the old live-build package list and independently assemble a new root filesystem. Therefore, build from a dedicated Debian 13 installation already configured as NEXORA OS.

Do not run the remaster script on your everyday computer or on an unrelated Debian installation. The script checks for the NEXORA release marker and Debian 13 before it proceeds.

## Requirements

- A dedicated Debian 13 Trixie amd64 build machine or virtual machine.
- NEXORA OS packages, branding, defaults and /etc/nexora-release installed on that system.
- The current official penguins-eggs package and its dependencies.
- Several gigabytes of free disk space; more is needed for a full KDE desktop image.

Install Penguins' eggs using its official package instructions. On a supported Debian-family system, the quick start documents:

~~~bash
sudo eggs tools repo add
~~~

Then install the package offered by the configured official repository if it is not already installed. Check the upstream quick start for current package instructions:
https://github.com/pieroproietti/penguins-eggs/blob/main/DOCS/2-user-manual/1-quickstart.md

## Configure the ISO identity

Before the first remaster, open the Eggs configuration interface:

~~~bash
sudo eggs config
~~~

Set the ISO prefix to nexora-os, choose the desired compression, and review the live-user settings. Keep the build in **Standard Live** mode. Do not use clone mode for distributable releases because clone mode is intended to preserve the source system's user accounts and personal data.

## Build

From the NEXORA OS source checkout on the configured NEXORA build system:

~~~bash
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
sudo ./scripts/build.sh
~~~

The ISO is placed in build-output/ and renamed to nexora-os-VERSION-ARCH.iso.

## Clean

Remove generated ISO files from this project's output directory:

~~~bash
rm -f build-output/*.iso
~~~

For an interrupted remaster, use the upstream cleanup command after checking the current Eggs documentation:

~~~bash
sudo eggs destroy
~~~

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
- If a build is interrupted, use sudo eggs destroy to clean up the remaster workspace before retrying.
