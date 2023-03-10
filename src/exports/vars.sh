#!/usr/bin/bash
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

export AVAILABLE_TARGETS="linux windows"
export AVAILABLE_ARCHS="x86_64 arm64 i686"
export AVAILABLE_ARTIFACTS="SOURCE BUILT PACKAGED MSIX NSIS WIN_PORTABLE"

if ! echo "$AVAILABLE_ARCHS" | grep -q "$ARCH"; then
  echo "Unsupported architecture $ARCH"
  exit 1
fi
