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

  if [ -f "$BSYS6/../assets/$TARGET.mozconfig" ]; then
    cat "$BSYS6/../assets/$TARGET.mozconfig" >>"mozconfig"
  fi
  echo "ac_add_options --target=$MOZ_TARGET" >>"mozconfig"

  echo "-> Running mach build with target $MOZ_TARGET" >&2
  if [ "${VERBOSE:-}" == "true" ]; then
    ./mach build -v
  else
    ./mach build
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
