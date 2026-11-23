# NEXORA OS — XFCE4 Desktop & Minimal

**Your Terminal. Your Universe.**

NEXORA OS is a Debian 13 Trixie-based operating system with two installation profiles. The main desktop edition is **NEXORA XFCE4**, a familiar XFCE desktop enhanced with NEXORA themes, wallpapers and integrated tools. NEXORA Minimal remains available for terminal-focused installations.

## Editions

| Edition | Image | Purpose |
| --- | --- | --- |
| **NEXORA OS XFCE4** | Live hybrid ISO | Main desktop edition. Boots directly into the complete NEXORA XFCE desktop and can be tried without installing. |
| **NEXORA OS Minimal** | GTK netinst ISO | Small terminal-focused installer for users who want a minimal system. |

## Downloads

For temporary test builds, see the [NEXORA OS testing guide](TESTING.md). It explains how to download successful CI artifacts, verify SHA-256 checksums and report problems.

Official ISO distribution is planned through **SourceForge File Release System (FRS)**. Each edition is uploaded only after its build, checksum verification and QEMU boot smoke test pass.

The SourceForge project page will be linked here after the project registration is completed.

Each published edition folder includes:
- The ISO image.
- A SHA-256 checksum file.
- A README with edition details and verification instructions.

## NEXORA XFCE4 Live

The main edition is built with Debian Live (`live-build`) on Debian 13 Trixie. It starts a complete XFCE4 session from the USB or virtual machine, with NEXORA wallpapers, four GTK themes, Welcome, Store, Control Center, Updater and the configurable NEXORA AI client.

The Live desktop includes **Install NEXORA OS**, our native GTK3 installation wizard. It detects disks, configures the account and installs the running Live system to the selected disk with an EFI/BIOS-aware partition layout and GRUB.

The native installer is an early implementation with automatic whole-disk partitioning. It erases the selected disk after an explicit confirmation. Back up your files and verify the target carefully; UEFI and BIOS virtual-machine installation tests are still required.

## Minimal netinst

NEXORA Minimal remains a separate, small Debian Installer GTK network installer for now. Replacing Debian Installer in the Minimal netinst image requires a separate custom boot/initrd integration; the native GTK installer currently belongs to the XFCE4 Live edition.

## Add NEXORA Desktop after installing Minimal

If you installed **NEXORA OS Minimal** with the terminal-only profile, you can add the NEXORA XFCE desktop later. You do not need to reinstall or repartition the system.

Connect to the internet and run:

```sh
sudo apt update
sudo apt install -y git ca-certificates
git clone --branch feature/nexora-minimal-terminal https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
sudo sh ./scripts/install-nexora-desktop.sh install
sudo reboot
```

The installer adds Debian's XFCE desktop task, LightDM, NetworkManager, audio and desktop utilities, then applies NEXORA wallpapers, themes, Welcome, Store, Control Center, Updater, and the fixed two-panel layout. Existing XFCE configuration files are backed up before NEXORA defaults are applied. It does not alter disk partitions or reinstall Debian.

After reboot, check the installation with:

```sh
nexora-desktop status
```

This requires Debian 13 (Trixie), an internet connection and administrator access. The NEXORA Store downloads optional apps from Flathub only when selected. The system remains based on Debian.

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

## Automatic SourceForge publishing

GitHub Actions builds and tests both editions. On pushes to the active development branch, a successful build is uploaded to SourceForge using rsync over SSH. Pull requests and manual workflow runs do not publish.

Configure these repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | Value |
| --- | --- |
| `SF_USERNAME` | Your SourceForge account username. |
| `SF_PROJECT` | The project's SourceForge URL/UNIX name. |
| `SF_SSH_PRIVATE_KEY` | The private SSH key whose public key is registered in your SourceForge account. |

The corresponding public key must be added to the SourceForge account, and the account must have permission to publish files in the project. Never commit a private key or paste it into an issue or chat.

The uploader verifies the official SourceForge FRS ED25519 host-key fingerprint before transferring files. It uses rsync so interrupted large uploads can resume.

## Project principles

- Provide a complete desktop that can be tested before installation.
- Keep NEXORA Minimal available as a separate terminal-focused option.
- Keep disk partitioning interactive and clearly confirm user choices.
- Measure image size and publish SHA-256 checksums for every release.
- Preserve Debian and upstream licenses and notices.
