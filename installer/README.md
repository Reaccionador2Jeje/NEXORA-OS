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

The ISO embeds original NEXORA artwork at `/nexora/branding/nexora-installer.svg` and a generated 1024×640 boot background. The build also creates 800×75 light and dark GTK banner logos and replaces all four upstream logo assets inside the installer's compressed initrd:
- `/usr/share/graphics/logo_debian.png`
- `/usr/share/graphics/logo_debian_dark.png`
- `/usr/share/graphics/logo_installer.png`
- `/usr/share/graphics/logo_installer_dark.png`

The GTK banner therefore displays NEXORA branding in both standard and dark theme variants, rather than Debian's logo. The initrd is unpacked, patched, repacked and checked during the ISO build.

## Installer interface status

The NEXORA artwork is now wired into both verified boot selectors: Syslinux/ISOLINUX for BIOS and GRUB for UEFI. The menu offers **NEXORA OS Minimal Terminal** and **NEXORA OS XFCE Desktop**, while retaining Debian's upstream rescue, expert and standard installer entries as fallback. Both NEXORA entries select the matching preseed and request the installer's built-in dark theme.

The GTK frontend now carries the NEXORA banner logo in both theme variants. The installer workflow, controls, dialog wording, package names and underlying GTK components remain Debian Installer components; this change does not claim to replace or fork the full frontend. The dark theme is Debian's built-in high-contrast theme, not a custom NEXORA color theme.

**Safety:** neither preseed profile defines automatic partitioning or silently confirms disk formatting.
