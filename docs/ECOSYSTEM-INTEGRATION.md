# NEXORA OS — Ecosystem Integration

Status: planning document; Debian-based image build and desktop integration must remain reproducible.

## Build principles
- Pin base image and package sources for reproducible builds.
- Keep image customization scripts reviewable and idempotent.
- Verify checksums for downloaded artifacts.
- Separate desktop, server and core editions into explicit build profiles.
- Keep bootable-image validation separate from installer and hardware-compatibility claims.

## Next tasks
1. Document the exact Debian base and package snapshot used by each build.
2. Add CI checks for shell script syntax and image manifest consistency.
3. Publish SHA-256 checksums for generated images.
4. Maintain a tested hardware/VM matrix and label untested devices clearly.