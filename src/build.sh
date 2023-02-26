#!/usr/bin/bash
set -eu

if [ -z "${BUILT:-}" ]; then
  source $BSYS6/utils/vars.sh
  source $BSYS6/utils/version.sh

  echo "-> Building LibreWolf $VERSION for $TARGET $ARCH" >&2

  source "$BSYS6/utils/source.sh"
  cd "$SOURCE"

  if [ -f "mozconfig" ]; then
    cp "mozconfig" "mozconfig.backup"
  else
    touch "mozconfig.backup"
  fi

  if [ -f "$BSYS6/../mozconfig/$TARGET.mozconfig" ]; then
    cat "$BSYS6/../mozconfig/$TARGET.mozconfig" >>"mozconfig"
  fi
  echo "ac_add_options --target=$MOZ_TARGET" >>"mozconfig"

  echo "-> Running mach build with target $MOZ_TARGET" >&2
  ./mach build
  export BUILT="$SOURCE/obj-$MOZ_TARGET/dist/librewolf"
fi
