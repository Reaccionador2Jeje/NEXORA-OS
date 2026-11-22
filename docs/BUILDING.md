# Building NEXORA OS

This guide describes the Hyper Lightweight XFCE4 live image.

## Target

- Debian GNU/Linux 13 (Trixie)
- amd64
- XFCE4 with NEXORA GTK styling
- LightDM GTK greeter
- Spanish (Chile) locale and Latin American keyboard layout
- Hybrid live ISO
- Flatpak with Flathub remote; no Flatpak applications or games preinstalled

The build configuration is maintained in `auto/config`. Package selection is in `config/package-lists/nexora-desktop.list.chroot`.

## Host requirements

Use a Debian 13 amd64 installation with a reliable internet connection. Building downloads the base system and packages and requires several gigabytes of free disk space. Run live-build as root.

Install the build tools:

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso
```

## Build

```bash
git clone https://github.com/Reaccionador2Jeje/NEXORA-OS.git
cd NEXORA-OS
chmod +x auto/config scripts/*.sh config/hooks/normal/*.hook.chroot
sudo ./scripts/check-dependencies.sh
sh ./scripts/validate-config.sh
sudo ./scripts/build.sh
```

The first build downloads the base filesystem and packages. The resulting ISO is moved to `build-output/`.

## Clean

```bash
sudo ./scripts/clean.sh
```

This removes generated live-build state, not source files in Git.

## Testing

Boot the ISO in a virtual machine before considering installation on physical hardware. Check:

1. The live boot menu appears.
2. LightDM displays the NEXORA-branded login screen.
3. The session starts in XFCE4, not KDE.
4. The NEXORA wallpaper, GTK theme and panel settings are applied.
5. Keyboard, pointer, display and NetworkManager work.
6. Audio works through PipeWire.
7. `flatpak remotes` lists Flathub.
8. No games or heavyweight desktop suites are installed by default.

This is an early development image. It is not a stable release and has not completed hardware compatibility or installation testing.

## Troubleshooting

- If a package cannot be found, verify the Debian suite and archive areas.
- If the build is interrupted, run `sudo lb clean` and start again.
- If disk space becomes low, clear generated caches rather than deleting source files.
- If the Flathub hook fails, inspect the build log and verify network access from the build environment.
