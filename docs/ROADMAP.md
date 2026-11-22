# NEXORA OS Roadmap

The roadmap describes source milestones, not guaranteed release dates. A checked item means the configuration or code exists; it does not imply that an ISO has built or booted successfully.

## 0.1.0 — Initial foundation

- [x] Create the repository and Debian Live build structure.
- [x] Define Debian 13 Trixie amd64 as the initial target.
- [x] Add the initial NEXORA logo and release identity.
- [ ] Complete a successful ISO build.
- [ ] Boot-test the initial image in a virtual machine.

## 0.2.0 — Hyper Lightweight XFCE

- [x] Replace KDE Plasma with XFCE4.
- [x] Replace SDDM with LightDM GTK Greeter.
- [x] Remove preinstalled games and game bundles.
- [x] Disable APT recommended-package installation.
- [x] Add NEXORA GTK3 dark theme.
- [x] Add NEXORA wallpaper and LightDM branding.
- [x] Configure a custom XFCE panel and user defaults.
- [x] Add Flatpak and configure Flathub.
- [x] Port NEXORA Welcome away from KDE dependencies.
- [x] Implement NEXORA Store with search, install, remove and update actions.
- [ ] Build and boot-test the XFCE ISO.
- [ ] Measure idle RAM, boot time and installed image size.

## 0.3.0 — NEXORA Store improvements

- [ ] Add application categories, including Games.
- [ ] Add screenshots, ratings and app detail pages.
- [ ] Add update notifications and safer progress reporting.
- [ ] Add a configurable per-user or system-wide install mode.

## 0.4.0 — NEXORA integration

- [ ] Package the NEXORA terminal for Debian.
- [ ] Integrate NEXORA tools into the desktop.
- [ ] Add update and maintenance utilities.

## 0.5.0 — Quality and release

- [ ] Test UEFI boot in virtual machines.
- [ ] Test display, audio, network, suspend and removable media.
- [ ] Publish checksums and build notes.
- [ ] Establish security updates and maintenance procedures.

## 1.0.0 — Stable release

- [ ] Complete release criteria.
- [ ] Publish reproducible release artifacts.
- [ ] Document supported hardware and update policy.
