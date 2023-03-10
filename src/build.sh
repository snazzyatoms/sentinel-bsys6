#!/usr/bin/bash
set -eu

if [ -z "${BUILT:-}" ]; then
  source $BSYS6/exports/target.sh
  source $BSYS6/exports/version.sh

  echo "-> Building LibreWolf $VERSION for $TARGET $ARCH" >&2

  source "$BSYS6/source.sh"

  echo "-> Running mach build with target $MOZ_TARGET" >&2
  if [ "${VERBOSE:-}" == "true" ]; then
    $SOURCE/mach build -v
  else
    $SOURCE/mach build
  fi

  if [ -d "$SOURCE/obj-$MOZ_TARGET/dist/librewolf" ]; then
    export BUILT="$SOURCE/obj-$MOZ_TARGET/dist/librewolf"
  elif [ -d "$SOURCE/obj-$MOZ_TARGET/dist/bin" ]; then
    export BUILT="$SOURCE/obj-$MOZ_TARGET/dist/bin"
  else
    echo "Could not find binary directory after build" >&2
    exit 1
  fi

  if [ "$TARGET" == "windows" ]; then
    cp -v "$BSYS6/../assets/librewolf.ico" "$BUILT"
  fi
fi
