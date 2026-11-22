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

## Installer interface status

The current graphical installer still uses Debian's upstream GTK screens. Boot menu inspection is automated so the next step can add NEXORA profile entries without guessing BIOS/UEFI config paths. A fully re-skinned GTK installer is not claimed yet.

**Safety:** neither preseed profile defines automatic partitioning or silently confirms disk formatting.
