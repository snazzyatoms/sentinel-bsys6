#!/usr/bin/bash
set -eu

if [ -z "${PACKAGED:-}" ]; then
  source $BSYS6/exports/target.sh
  source $BSYS6/exports/build_use_existing.sh

  echo "-> Packaging locales (output hidden)" >&2
  locales="$(cat "$SOURCE/browser/locales/shipped-locales")"
  export MOZ_CHROME_MULTILOCALE="$(echo "$locales" | tr '\n' ' ')"
  echo "$locales" | sed s/^/chrome-/ | xargs make -j$(nproc) -C "$SOURCE/obj-$MOZ_TARGET" >/dev/null 2>/dev/null

  echo "-> Running 'mach package'" >&2
  "$SOURCE/mach" package
  if [ "$TARGET" == "windows" ]; then
    source $BSYS6/exports/move_artifact.sh "PACKAGED" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*win64\.zip"
  else
    source $BSYS6/exports/move_artifact.sh "PACKAGED" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*\.tar\.bz2"
  fi
  source $BSYS6/exports/calculate_sha256.sh "PACKAGED"
fi
