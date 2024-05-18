#!/usr/bin/env bash
set -e

source $BSYS6/source.sh

echo "-> Fetching and extracting Windows SDK with mach"
$SOURCE/mach --no-interactive python --virtualenv build "$SOURCE/taskcluster/scripts/misc/get_vs.py" "$SOURCE/build/vs/vs2022.yaml" "$MOZBUILD/win-cross"
