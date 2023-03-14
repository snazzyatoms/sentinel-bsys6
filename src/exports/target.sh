#!/usr/bin/bash
set -eu

# Extension of vars.sh, but kept in a seperate file because
# sometimes we want TARGET to be undefined, to be able to set
# it to the right value when needed in require_target.sh.

if [ -z "${TARGET:-}" ]; then
  export TARGET="linux"
fi

case $TARGET in
linux)
  export MOZ_TARGET="$ARCH-pc-linux-gnu"
  ;;
windows)
  export MOZ_TARGET="$ARCH-pc-mingw32"
  ;;
dind) ;;
*)
  echo "Unsupported target $TARGET"
  exit 1
  ;;
esac
