#!/usr/bin/bash
set -eu

source $BSYS6/utils/version.sh

if [ -z "${SOURCE:-}" ]; then
  if [ -d "$SOURCEDIR" ]; then
    if [ -f "$SOURCEDIR/mozconfig.backup" ]; then
      rm -f "$SOURCEDIR/mozconfig"
      mv "$SOURCEDIR/mozconfig.backup" "$SOURCEDIR/mozconfig"
    fi
  else
    echo "-> Fetching librewolf-$VERSION.source.tar.gz" >&2

    source $BSYS6/require.sh tar

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
