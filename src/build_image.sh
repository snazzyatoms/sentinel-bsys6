#!/usr/bin/bash
set -e -o pipefail

source $BSYS6/require.sh docker

source $BSYS6/utils/vars.sh

echo "-> Building docker $TARGET image" >&2
cd "$BSYS6/.."
docker build -t "registry.gitlab.com/librewolf-community/browser/bsys6/$TARGET" --build-arg TARGET . -f src/Dockerfile
