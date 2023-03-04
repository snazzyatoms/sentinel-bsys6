#!/usr/bin/bash
set -e -o pipefail

source $BSYS6/utils/vars.sh
source $BSYS6/utils/version.sh

docker run --rm -v "$(pwd)":"/bsys6" -e TARGET="$TARGET" -e ARCH="$ARCH" -e VERSION="$VERSION" "registry.gitlab.com/librewolf-community/browser/bsys6/$TARGET" sh -c "./bsys6 build"
