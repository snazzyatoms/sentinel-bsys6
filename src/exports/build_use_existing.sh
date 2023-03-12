#!/usr/bin/bash
set -eu

source $BSYS6/exports/target.sh

if [ -z "${BUILT:-}" ]; then
  source "$BSYS6/source.sh"
  source "$BSYS6/exports/version.sh"

  if [ -d "$SOURCEDIR/obj-$MOZ_TARGET/dist/librewolf" ] && [ -z "${MOZCONFIG_CHANGED:-}" ]; then
    export SOURCE="$SOURCEDIR"
    export BUILT="$SOURCEDIR/obj-$MOZ_TARGET/dist/librewolf"
  elif [ -d "$SOURCEDIR/obj-$MOZ_TARGET/dist/bin" ] && [ -z "${MOZCONFIG_CHANGED:-}" ]; then
    export SOURCE="$SOURCEDIR"
    export BUILT="$SOURCEDIR/obj-$MOZ_TARGET/dist/bin"
  else
    source "$BSYS6/build.sh"
  fi
fi
