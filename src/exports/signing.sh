#!/usr/bin/env bash
set -eu

if [ -z "${SIGNING:-}" ]; then
  if [[ -f pk.asc ]]; then
    echo "-> Private key for signing is available, importing..." >&2
    gpg --import pk.asc
    cat >>~/.rpmmacros <<EOF
%_signature gpg
%_gpg_name  LibreWolf Maintainers
EOF
    export SIGNING="true"
  fi
fi
