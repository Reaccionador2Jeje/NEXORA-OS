# Installer integration

NEXORA now has two separate image-building paths.

## NEXORA XFCE4 Live (main edition)

The main desktop image is built with Debian Live using `scripts/build-live.sh`. It includes the complete XFCE4 desktop, the NEXORA desktop overlay and Debian Installer in Live mode.

The Live session starts directly at the XFCE desktop. Users can explore the system without installing it. The **Install NEXORA OS** desktop shortcut runs:

```sh
debian-installer-launcher live
```

This launches Debian Installer from the desktop. Its Live installer copies the running filesystem to the selected destination and then configures the bootloader and installed system. The installer is interactive; NEXORA does not preselect or silently confirm disk formatting.

The Live image includes:
- Five NEXORA wallpapers and four GTK themes.
- NEXORA Welcome, Store, Control Center and Updater.
- NEXORA AI client, configurable for a local Ollama-compatible endpoint or another OpenAI-compatible service.
- XFCE4, NetworkManager, PolicyKit, Flatpak and common desktop utilities.
- Debian Installer desktop launcher and the Live installer boot option.

The Live desktop itself can be used without installing. An Internet connection is recommended for browsing, updates and services that need network access.

## NEXORA Minimal netinst

The Minimal image continues to use Debian Installer GTK. It embeds the `preseed/minimal.cfg` and `preseed/desktop.cfg` profiles and the NEXORA installer branding. Minimal remains terminal-focused; the old XFCE preseed is retained for the separate netinst workflow.

The installer uses Chilean Spanish and the Latin American keyboard layout by default. Disk partitioning remains interactive.

## Installer branding

The netinst image embeds NEXORA artwork at `/nexora/branding/nexora-installer.svg` and a generated boot background. The GTK initrd banner is rebranded for the installer-based Minimal image.

The XFCE4 Live image instead uses Debian Live boot menus and starts the XFCE session. It does not boot directly into the GTK installer.
