#!/usr/bin/bash
set -eu

source $BSYS6/exports/target.sh
source $BSYS6/exports/version.sh

docker run --rm -v "$BSYS6/..":"/bsys6" -v "$WORKDIR":"/root/bsys6/work" -e TARGET="$TARGET" -e ARCH="$ARCH" -e VERSION="$VERSION" "registry.gitlab.com/librewolf-community/browser/bsys6/$TARGET" sh -c "./bsys6 build"
