#!/usr/bin/bash
set -eu

source $BSYS6/exports/target.sh
$BSYS6/utils/require.sh docker

echo "-> Building docker $TARGET image" >&2
(cd "$BSYS6/.." && docker build --progress=plain -t "registry.gitlab.com/maltejur/bsys6/$TARGET" --build-arg TARGET . -f assets/Dockerfile)
