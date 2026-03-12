#!/usr/bin/env bash
set -e

if [ -f "$BSYS6/../env.sh" ]; then
  source $BSYS6/../env.sh
fi

if [ -z "$BSYS6" ]; then
  export BSYS6="$(dirname "$(readlink -f "$0/..")")"
fi

if [ -z "${ARCH:-}" ]; then
  export ARCH="x86_64"
fi

if [ -z "${MOZBUILD:-}" ]; then
  export MOZBUILD="$HOME/.mozbuild"
fi

if [ -z "${WORKDIR:-}" ]; then
  export WORKDIR="$HOME/.local/share/bsys6/work"
fi
mkdir -p "$WORKDIR"

export AVAILABLE_TARGETS="linux windows macos dind release"
export AVAILABLE_ARCHS="x86_64 arm64"
export AVAILABLE_ARTIFACTS="SOURCE PACKAGE MSIX SETUP PORTABLE NUPKG DEB RPM WINUPDATER"

if ! $BSYS6/utils/list_contains.sh "$AVAILABLE_ARCHS" "$ARCH"; then
  echo "Unsupported architecture $ARCH"
  exit 1
fi

if [ -z "${FORGE_URL:-}" ]; then
  export FORGE_URL="https://codeberg.org"
fi

if [ -z "${FORGE_REPO_OWNER:-}" ]; then
  export FORGE_REPO_OWNER="librewolf"
fi

if [ -z "${FORGE_REPO:-}" ]; then
  export FORGE_REPO="librewolf/bsys6"
fi
