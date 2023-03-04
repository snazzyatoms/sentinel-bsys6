#!/usr/bin/bash
set -e -o pipefail

source $BSYS6/require.sh docker

source $BSYS6/utils/vars.sh

echo "-> Building docker $TARGET image" >&2
cd "$BSYS6/.."
docker build --progress=plain -t "registry.gitlab.com/maltejur/bsys6/$TARGET" --build-arg TARGET . -f src/Dockerfile
