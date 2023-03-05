#!/usr/bin/bash
set -eu

if [ -z "${BUILT:-}" ]; then
  source "$BSYS6/utils/version.sh"

  if [ -d "$SOURCEDIR/obj-$MOZ_TARGET/dist/librewolf" ]; then
    export SOURCE="$SOURCEDIR"
    export BUILT="$SOURCEDIR/obj-$MOZ_TARGET/dist/librewolf"
  elif [ -d "$SOURCEDIR/obj-$MOZ_TARGET/dist/bin" ]; then
    export SOURCE="$SOURCEDIR"
    export BUILT="$SOURCEDIR/obj-$MOZ_TARGET/dist/bin"
  else
    source "$BSYS6/build.sh"
  fi
fi
