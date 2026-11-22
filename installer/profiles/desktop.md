# NEXORA XFCE4 desktop profile

The NEXORA XFCE4 profile installs Debian's `xfce-desktop` task together with the NEXORA desktop overlay.

The overlay configures the new desktop with:

- Five NEXORA wallpapers and a default NEXORA background.
- Four GTK themes: NEXORA, NEXORA Midnight, NEXORA Ocean and NEXORA Light.
- NEXORA Welcome, Store, Control Center and Updater launchers.
- NEXORA AI desktop client, configurable for an OpenAI-compatible endpoint or a local Ollama-compatible service.
- PolicyKit agent and XFCE defaults for new and existing user accounts.

The XFCE4 release image selects this profile by default from both BIOS and UEFI boot menus. Minimal Terminal remains available as an alternate profile.

The installer requires a working network connection to download Debian packages. Disk partitioning remains interactive; the profile does not configure automatic partitioning or silently confirm formatting.
