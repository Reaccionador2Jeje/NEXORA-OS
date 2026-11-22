#!/bin/sh
# Publish a verified NEXORA ISO to SourceForge's File Release System (FRS).
set -eu

: "${SF_USERNAME:?Set SF_USERNAME to your SourceForge account username}"
: "${SF_PROJECT:?Set SF_PROJECT to the SourceForge project UNIX name}"
: "${SF_SSH_PRIVATE_KEY:?Set SF_SSH_PRIVATE_KEY to the private SSH key registered with SourceForge}"
: "${NEXORA_ISO_PATH:?Set NEXORA_ISO_PATH to the ISO path}"
: "${NEXORA_RELEASE_DIR:?Set NEXORA_RELEASE_DIR to a safe release folder name}"
: "${NEXORA_RELEASE_TITLE:?Set NEXORA_RELEASE_TITLE to the release title}"
: "${NEXORA_RELEASE_DESCRIPTION:?Set NEXORA_RELEASE_DESCRIPTION to a short description}"

case "$SF_PROJECT" in
  *[!a-z0-9-]*|"") echo "ERROR: SF_PROJECT must contain only lowercase letters, numbers and hyphens." >&2; exit 2 ;;
esac
case "$SF_USERNAME" in
  *[!A-Za-z0-9._-]*|"") echo "ERROR: SF_USERNAME contains unsupported characters." >&2; exit 2 ;;
esac
case "$NEXORA_RELEASE_DIR" in
  *[!A-Za-z0-9._-]*|"") echo "ERROR: NEXORA_RELEASE_DIR contains unsupported characters." >&2; exit 2 ;;
esac

ISO_PATH="$NEXORA_ISO_PATH"
CHECKSUM_PATH="${ISO_PATH}.sha256"
ISO_NAME=$(basename "$ISO_PATH")

if [ ! -s "$ISO_PATH" ]; then
  echo "ERROR: ISO not found or empty: $ISO_PATH" >&2
  exit 1
fi
if [ ! -s "$CHECKSUM_PATH" ]; then
  echo "ERROR: SHA256 file not found or empty: $CHECKSUM_PATH" >&2
  exit 1
fi

# Never publish an image that does not match the checksum produced by CI.
(
  cd "$(dirname "$ISO_PATH")"
  sha256sum --check "$(basename "$CHECKSUM_PATH")"
)

WORK_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT HUP INT TERM

KEY_FILE="$WORK_DIR/sourceforge_key"
KNOWN_HOSTS="$WORK_DIR/known_hosts"
PAYLOAD_DIR="$WORK_DIR/payload"
RELEASE_PATH="$PAYLOAD_DIR/$NEXORA_RELEASE_DIR"

umask 077
printf '%s\n' "$SF_SSH_PRIVATE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"
mkdir -p "$RELEASE_PATH"

cp "$ISO_PATH" "$RELEASE_PATH/$ISO_NAME"
(
  cd "$RELEASE_PATH"
  sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
)

cat > "$RELEASE_PATH/README.md" <<EOF
# $NEXORA_RELEASE_TITLE

$NEXORA_RELEASE_DESCRIPTION

- Architecture: amd64 (x86_64)
- ISO: $ISO_NAME
- Checksum: $ISO_NAME.sha256

## Verify the download

Run this in the directory containing the ISO and checksum:

```sh
sha256sum --check $ISO_NAME.sha256
```

This is an experimental build. Test it in a virtual machine before using it on a physical computer.
EOF

# Pin the SourceForge FRS ED25519 host key using its published SHA-256 fingerprint.
# Source: https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/
ssh-keyscan -T 15 -t ed25519 frs.sourceforge.net 2>/dev/null > "$KNOWN_HOSTS"
if [ ! -s "$KNOWN_HOSTS" ]; then
  echo "ERROR: Could not retrieve the SourceForge FRS host key." >&2
  exit 1
fi
HOST_FINGERPRINT=$(ssh-keygen -lf "$KNOWN_HOSTS" -E sha256 | awk 'NR == 1 { print $2 }')
EXPECTED_FINGERPRINT="SHA256:209BDmH3jsRyO9UeGPPgLWPSegKmYCBIya0nR/AWWCY"
if [ "$HOST_FINGERPRINT" != "$EXPECTED_FINGERPRINT" ]; then
  echo "ERROR: SourceForge FRS host key fingerprint did not match the published ED25519 fingerprint." >&2
  exit 1
fi

SSH_COMMAND="ssh -i $KEY_FILE -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$KNOWN_HOSTS"
DESTINATION="$SF_USERNAME@frs.sourceforge.net:/home/frs/project/$SF_PROJECT/"

echo "Uploading $NEXORA_RELEASE_DIR to SourceForge project $SF_PROJECT..."
rsync -avP -e "$SSH_COMMAND" "$PAYLOAD_DIR/" "$DESTINATION"
echo "SourceForge upload completed."
