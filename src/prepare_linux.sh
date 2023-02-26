#!/usr/bin/bash
set -e -o pipefail

source $BSYS6/utils/require_target.sh "linux"
source $BSYS6/utils/version.sh

source $BSYS6/bootstrap.sh
source $BSYS6/artifact.sh "sysroot-wasm32-wasi" "linux64-cbindgen"
