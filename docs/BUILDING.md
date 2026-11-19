# Building NEXORA OS

This guide describes the first Desktop live image build.

## Target

- Debian 13 (Trixie)
- amd64
- KDE Plasma
- Spanish (Chile) locale and Latin American keyboard layout
- Hybrid live ISO

The build configuration is maintained in `auto/config`. Package selection is in `config/package-lists/`.

## Host requirements

Use a Debian 13 amd64 installation with a reliable internet connection. A live image build downloads packages and needs several gigabytes of free disk space. Building as root is required by live-build.

Install the required tools:

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso
```

## Build

```bash
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
chmod +x auto/config scripts/*.sh
sudo ./scripts/check-dependencies.sh
sudo ./scripts/build.sh
```

The first build can take a while because packages and the base filesystem must be downloaded. The resulting ISO is moved to `build-output/`.

## Clean

To remove generated live-build state before a fresh build:

```bash
sudo ./scripts/clean.sh
```

This removes generated build artifacts, not the source files in Git.

## Testing

Use a virtual machine first. Boot the ISO and check:
1. The live boot menu appears.
2. The system reaches the KDE Plasma desktop.
3. Display, keyboard and pointer work.
4. Network Manager can detect available network interfaces.
5. The selected locale and keyboard layout are correct.

Do not install this early development image on a primary machine. It is a test image and has not yet completed installation or hardware compatibility testing.

## Troubleshooting

- If a package cannot be found, confirm the configured Debian suite and archive areas.
- If the build is interrupted, run `sudo lb clean` and start again.
- If disk space becomes low, free space before retrying; do not remove files from the source tree to solve a generated-cache problem.
