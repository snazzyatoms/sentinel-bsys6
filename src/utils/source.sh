#!/usr/bin/bash
set -eu

source $BSYS6/utils/version.sh

if [ -n "${SOURCE:-}" ]; then
  if [ -f "$SOURCE/mozconfig.back" ]; then
    rm -f "$SOURCE/mozconfig"
    mv "$SOURCE/mozconfig.back" "$SOURCE/mozconfig"
  fi
else
  source $BSYS6/require.sh tar

  if [ ! -d "$SOURCEDIR" ]; then
    echo "-> Fetching librewolf-$VERSION.source.tar.gz" >&2

    mkdir -p "$SOURCEDIR/.." >&2
    mkdir -p "$WORKDIR" >&2

    curl -o "$WORKDIR/librewolf-$VERSION.source.tar.gz" "https://gitlab.com/api/v4/projects/32320088/packages/generic/librewolf-source/$VERSION/librewolf-$VERSION.source.tar.gz" >&2

    echo "-> Extracting librewolf-$VERSION.source.tar.gz" >&2
    tar xf "$WORKDIR/librewolf-$VERSION.source.tar.gz" -C "$SOURCEDIR/.." >&2
    if [ "$(readlink -f "$SOURCEDIR")" != "$(readlink -f "$SOURCEDIR/../librewolf-$VERSION")" ]; then
      mv "$SOURCEDIR/../librewolf-$VERSION" "$SOURCEDIR" >&2
    fi
    rm "$WORKDIR/librewolf-$VERSION.source.tar.gz" >&2
  fi

  export SOURCE="$SOURCEDIR"
fi
