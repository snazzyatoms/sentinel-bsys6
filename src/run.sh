#!/usr/bin/bash
set -eu

source $BSYS6/exports/build_use_existing.sh
$SOURCE/mach run $@
exit 0
