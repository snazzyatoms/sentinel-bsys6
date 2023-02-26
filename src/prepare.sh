#!/usr/bin/bash
set -e

source $BSYS6/utils/vars.sh

echo "-> Preparing build environment for $TARGET target"
source $BSYS6/prepare_$TARGET.sh
