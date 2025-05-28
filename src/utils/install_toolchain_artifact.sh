#!/usr/bin/env bash
set -eu

source $BSYS6/source.sh

cd "$MOZBUILD"

while [[ $# -gt 0 ]]; do
  echo "-> Fetching toolchain artifact $1"
  case $1 in
    linux64-binutils)
      $SOURCE/mach artifact toolchain --from-task JqrrfAabSU2BRwlxnEq9zQ:public/build/binutils.tar.zst
      ;;
    *)
      $SOURCE/mach artifact toolchain --from-build "$1"
      ;;
  esac
  shift
done
