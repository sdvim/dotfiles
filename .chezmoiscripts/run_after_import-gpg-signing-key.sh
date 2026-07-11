#!/bin/sh
set -eu

key_fingerprint="59CCEAA377B73C77742851E4333487C4FFB88C8D"
key_ref="op://Private/GPG Secret Key/notesPlain"

if ! command -v op >/dev/null 2>&1; then
  echo "import-gpg-signing-key: op was not found" >&2
  exit 127
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "import-gpg-signing-key: gpg was not found" >&2
  exit 127
fi

if ! gpg --list-secret-keys "$key_fingerprint" >/dev/null 2>&1; then
  op read "$key_ref" | gpg --batch --import
fi

if ! gpg --list-secret-keys "$key_fingerprint" >/dev/null 2>&1; then
  echo "import-gpg-signing-key: imported key was not found" >&2
  exit 1
fi

printf '%s:6:\n' "$key_fingerprint" | gpg --import-ownertrust
