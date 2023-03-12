#!/usr/bin/bash
set -eu

source $BSYS6/exports/build_use_existing.sh

echo "-> Running 'mach run'" >&2
$SOURCE/mach run $@
exit 0
