# NEXORA Minimal native installer boot

The Minimal GTK ISO boots a Debian Live installer runtime and automatically starts the native NEXORA GTK wizard.

## Boot flow

1. Boot the ISO using BIOS or UEFI.
2. Select the NEXORA Minimal entry from the branded boot menu.
3. LightDM starts the lightweight Openbox session and logs in to the temporary live account.
4. Openbox autostart launches python3 /usr/bin/nexora-installer.
5. The native wizard configures the target disk, locale, keyboard, timezone, account, root access, network, APT mirror and installed desktop profile.

## Installed profiles

- **NEXORA Minimal:** installs a terminal-focused system and removes the temporary Openbox/LightDM/Xorg graphical installer runtime.
- **NEXORA XFCE4:** installs the XFCE4 desktop and LightDM.

Disk partitioning is whole-disk and destructive. The installer displays a final review and requires explicit confirmation before modifying the selected disk. Back up important data and verify the selected disk carefully.

The ISO build checks the installer executable, engine, auto-login and autostart configuration, and required runtime packages. A successful build is not a substitute for testing a full install in both BIOS and UEFI virtual machines.
