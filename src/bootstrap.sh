#!/usr/bin/bash
set -eu

source $BSYS6/utils/vars.sh
source $BSYS6/utils/source.sh

cd "$SOURCE"

echo "-> Bootstrapping the build system with mach"
./mach --no-interactive bootstrap --application-choice=browser
