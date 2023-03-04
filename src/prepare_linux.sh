#!/usr/bin/bash
set -eu

source $BSYS6/utils/require_target.sh "linux"
source $BSYS6/utils/version.sh

echo "-> Preparing build environment for native linux build (target: linux)"

source $BSYS6/bootstrap.sh
source $BSYS6/artifact.sh "sysroot-wasm32-wasi" "linux64-cbindgen"
