#!/usr/bin/bash
set -eu

if [ -z "${PACKAGED:-}" ]; then
  source "$BSYS6/utils/vars.sh"
  source "$BSYS6/build_use_existing.sh"

  echo "-> Running mach package (output hidden)" >&2
  cat "$SOURCE/browser/locales/shipped-locales" | xargs $SOURCE/mach package-multi-locale --locales >/dev/null
  source "$BSYS6/utils/move_artifact.sh" "PACKAGED" "$SOURCE/obj-$MOZ_TARGET/dist" "librewolf-.*\.tar\.bz2"
  source "$BSYS6/utils/calculate_sha256.sh" "PACKAGED"
fi
