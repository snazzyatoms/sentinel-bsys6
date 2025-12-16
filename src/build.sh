#!/usr/bin/env bash
set -eu

source $BSYS6/exports/target.sh
source $BSYS6/exports/version.sh

source "$BSYS6/source.sh"

echo "-> Running 'mach build'" >&2
# We need to be in the $SOURCE directory, otherwise the path could be too long for
# the Microsoft (R) Macro Assembler.
if [ "${VERBOSE:-}" == "true" ]; then
  (cd $SOURCE && ./mach build -v)
else
  (cd $SOURCE && ./mach build)
fi

if [ "$TARGET" == "windows" ]; then
  $BSYS6/utils/sign_exe.sh "$SOURCE/obj-$MOZ_TARGET/dist/bin/librewolf.exe"
fi
