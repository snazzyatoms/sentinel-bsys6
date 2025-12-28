#!/usr/bin/env bash
set -eu

$BSYS6/utils/require_command.sh awk gpg

if [ -n "${SIGNING_KEY:-}" ] && [ -z "${SIGNING_KEY_FPR:-}" ]; then
  echo "-> Setting up gpg signing using provided private key," >&2
  export SIGNING_KEY_FPR="$(echo -e "$SIGNING_KEY" | gpg --with-colons --import-options show-only --import --fingerprint | awk -F: '$1 == "fpr" {print $10;}' | head -n 1)"
  echo "   fingerprint is '$SIGNING_KEY_FPR'" >&2
  echo -e "$SIGNING_KEY" | gpg --import
  cat >>~/.rpmmacros <<EOF
%_signature gpg
%_gpg_name  LibreWolf Maintainers
EOF
fi
