#!/usr/bin/bash
set -eu

source $BSYS6/source.sh

cd "$MOZBUILD"
while [[ $# -gt 0 ]]; do
  echo "-> Fetching artifact $1"
  $SOURCE/mach artifact toolchain --from-build "$1"
  shift
done
