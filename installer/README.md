# Installer integration

NEXORA OS Minimal uses Debian Installer GTK. The ISO embeds the `desktop-overlay/` tree and two Preseed profiles.

## Minimal Terminal

The Minimal profile installs standard system utilities only and does not select a desktop task. Installer defaults use Chilean Spanish and the Latin American keyboard layout. Disk partitioning remains interactive.

## NEXORA XFCE Desktop

The XFCE profile installs Debian's XFCE task plus Flatpak, GTK3/PyGObject, PolicyKit and XFCE utilities. Its late-command copies the NEXORA overlay into the target system and applies desktop defaults.

Included desktop features:

- Five NEXORA wallpapers under `/usr/share/backgrounds/nexora`.
- Four GTK themes: NEXORA, NEXORA Midnight, NEXORA Ocean and NEXORA Light.
- NEXORA Welcome, NEXORA Store and NEXORA Control Center.
- NEXORA AI client, configurable for a local Ollama-compatible endpoint or another OpenAI-compatible service.
- NEXORA updater launcher and PolicyKit agent.

The AI client is integrated as a desktop application, but it does not bundle a model or provider credentials. Configure an available local or compatible service in its Connection dialog. No API key is shipped in the ISO.

## NEXORA installer branding

The ISO now embeds original NEXORA installer artwork at `/nexora/branding/nexora-installer.svg` and a generated 1024×640 background at `/nexora/nexora-installer-background.png`. The visual identity uses midnight navy, cyan and violet, with the NEXORA wordmark and installation label. The build verifies that these assets are present.

## Installer interface status

The artwork is packaged, but Debian Installer's GTK dialogs are not yet re-skinned and the artwork is not yet wired into the live GTK frontend. The boot-menu inspection is automated; the next implementation step is to apply a branded boot menu to verified BIOS/UEFI configuration files while preserving the upstream fallback. A fully re-skinned GTK installer is not claimed yet.

**Safety:** neither preseed profile defines automatic partitioning or silently confirms disk formatting.
