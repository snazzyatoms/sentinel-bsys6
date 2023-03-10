#!/usr/bin/bash
set -eu

if [ -z "${PACKAGED:-}" ]; then
  source $BSYS6/exports/target.sh
  source $BSYS6/exports/build_use_existing.sh

  echo "-> Running mach package" >&2
  "$SOURCE/mach" package
  if [ "$TARGET" == "windows" ]; then
    source $BSYS6/exports/move_artifact.sh "PACKAGED" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*win64\.zip"
  else
    source $BSYS6/exports/move_artifact.sh "PACKAGED" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*\.tar\.bz2"
  fi
  source $BSYS6/exports/calculate_sha256.sh "PACKAGED"
fi
